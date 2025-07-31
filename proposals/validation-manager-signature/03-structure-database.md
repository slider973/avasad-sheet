# Structure de Base de Données - Supabase

## Schéma de base de données

### 1. Table: `organizations`

```sql
CREATE TABLE organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  domain VARCHAR(255),
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX idx_organizations_domain ON organizations(domain);
```

### 2. Table: `users`

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  organization_id UUID REFERENCES organizations(id),
  role VARCHAR(50) CHECK (role IN ('employee', 'manager', 'admin')),
  fcm_token TEXT,
  preferences JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour les requêtes fréquentes
CREATE INDEX idx_users_organization ON users(organization_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_email ON users(email);
```

### 3. Table: `manager_assignments`

```sql
CREATE TABLE manager_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES users(id),
  manager_id UUID REFERENCES users(id),
  start_date DATE NOT NULL,
  end_date DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Contrainte pour éviter les doublons actifs
  CONSTRAINT unique_active_assignment 
    UNIQUE (employee_id, manager_id, is_active) 
    WHERE is_active = true
);

-- Index pour les recherches
CREATE INDEX idx_manager_assignments_employee ON manager_assignments(employee_id);
CREATE INDEX idx_manager_assignments_manager ON manager_assignments(manager_id);
CREATE INDEX idx_active_assignments ON manager_assignments(is_active) WHERE is_active = true;
```

### 4. Table: `timesheet_validations`

```sql
CREATE TABLE timesheet_validations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES organizations(id) NOT NULL,
  employee_id UUID REFERENCES users(id) NOT NULL,
  manager_id UUID REFERENCES users(id) NOT NULL,
  
  -- Données de la timesheet
  timesheet_month INTEGER NOT NULL CHECK (timesheet_month BETWEEN 1 AND 12),
  timesheet_year INTEGER NOT NULL CHECK (timesheet_year >= 2020),
  timesheet_data JSONB NOT NULL,
  
  -- URLs des PDFs (chiffrés dans Storage)
  original_pdf_url TEXT NOT NULL,
  signed_pdf_url TEXT,
  
  -- Statut et timestamps
  status VARCHAR(20) NOT NULL DEFAULT 'submitted' 
    CHECK (status IN ('submitted', 'validated', 'rejected', 'error', 'expired')),
  submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  validated_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  
  -- Métadonnées
  metadata JSONB DEFAULT '{}',
  
  -- Contrainte d'unicité pour éviter les doublons
  CONSTRAINT unique_validation_per_period 
    UNIQUE (employee_id, timesheet_month, timesheet_year)
);

-- Index pour performance
CREATE INDEX idx_validations_status ON timesheet_validations(status);
CREATE INDEX idx_validations_manager ON timesheet_validations(manager_id, status);
CREATE INDEX idx_validations_employee ON timesheet_validations(employee_id, status);
CREATE INDEX idx_validations_expires ON timesheet_validations(expires_at);
CREATE INDEX idx_validations_period ON timesheet_validations(timesheet_year, timesheet_month);
```

### 5. Table: `validation_feedback`

```sql
CREATE TABLE validation_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  validation_id UUID REFERENCES timesheet_validations(id) NOT NULL,
  created_by UUID REFERENCES users(id) NOT NULL,
  feedback_type VARCHAR(20) CHECK (feedback_type IN ('error', 'comment', 'approval')),
  
  -- Détails des erreurs
  errors JSONB DEFAULT '[]',
  general_comment TEXT,
  
  -- Statut
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMP WITH TIME ZONE,
  resolved_by UUID REFERENCES users(id),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX idx_feedback_validation ON validation_feedback(validation_id);
CREATE INDEX idx_feedback_unresolved ON validation_feedback(is_resolved) WHERE is_resolved = false;
```

### 6. Table: `validation_history`

```sql
CREATE TABLE validation_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  validation_id UUID REFERENCES timesheet_validations(id) NOT NULL,
  action VARCHAR(50) NOT NULL,
  performed_by UUID REFERENCES users(id) NOT NULL,
  previous_status VARCHAR(20),
  new_status VARCHAR(20),
  details JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index pour audit trail
CREATE INDEX idx_history_validation ON validation_history(validation_id);
CREATE INDEX idx_history_user ON validation_history(performed_by);
CREATE INDEX idx_history_date ON validation_history(created_at);
```

### 7. Table: `notification_logs`

```sql
CREATE TABLE notification_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id UUID REFERENCES users(id) NOT NULL,
  notification_type VARCHAR(50) NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}',
  
  -- Statut de livraison
  status VARCHAR(20) DEFAULT 'pending' 
    CHECK (status IN ('pending', 'sent', 'delivered', 'failed')),
  sent_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT,
  
  -- FCM specific
  fcm_message_id TEXT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX idx_notifications_recipient ON notification_logs(recipient_id);
CREATE INDEX idx_notifications_status ON notification_logs(status);
```

## Row Level Security (RLS)

### 1. Politique pour `timesheet_validations`

```sql
-- Activer RLS
ALTER TABLE timesheet_validations ENABLE ROW LEVEL SECURITY;

-- Les employés peuvent voir leurs propres validations
CREATE POLICY "Employees can view own validations"
  ON timesheet_validations FOR SELECT
  USING (auth.uid() = employee_id);

-- Les managers peuvent voir les validations qui leur sont assignées
CREATE POLICY "Managers can view assigned validations"
  ON timesheet_validations FOR SELECT
  USING (auth.uid() = manager_id);

-- Les employés peuvent créer des validations
CREATE POLICY "Employees can create validations"
  ON timesheet_validations FOR INSERT
  WITH CHECK (auth.uid() = employee_id);

-- Les managers peuvent mettre à jour les validations
CREATE POLICY "Managers can update validations"
  ON timesheet_validations FOR UPDATE
  USING (auth.uid() = manager_id)
  WITH CHECK (auth.uid() = manager_id);
```

### 2. Politique pour `validation_feedback`

```sql
ALTER TABLE validation_feedback ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs peuvent voir les feedbacks liés à leurs validations
CREATE POLICY "Users can view related feedback"
  ON validation_feedback FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM timesheet_validations tv
      WHERE tv.id = validation_feedback.validation_id
      AND (tv.employee_id = auth.uid() OR tv.manager_id = auth.uid())
    )
  );

-- Les managers peuvent créer des feedbacks
CREATE POLICY "Managers can create feedback"
  ON validation_feedback FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM timesheet_validations tv
      WHERE tv.id = validation_id
      AND tv.manager_id = auth.uid()
    )
  );
```

## Storage Buckets

### 1. Bucket: `timesheet-pdfs`

```sql
-- Structure des dossiers
-- /timesheet-pdfs/
--   /{organization_id}/
--     /pending/
--       /{employee_id}/
--         /timesheet_{timestamp}.pdf
--     /validated/
--       /{validation_id}/
--         /signed_{timestamp}.pdf

-- Politique de sécurité
CREATE POLICY "Users can upload own PDFs"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'timesheet-pdfs' AND
    auth.uid()::text = (string_to_array(name, '/'))[3]
  );

CREATE POLICY "Users can read assigned PDFs"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'timesheet-pdfs' AND
    EXISTS (
      SELECT 1 FROM timesheet_validations tv
      WHERE (tv.employee_id = auth.uid() OR tv.manager_id = auth.uid())
      AND (tv.original_pdf_url LIKE '%' || name || '%' 
           OR tv.signed_pdf_url LIKE '%' || name || '%')
    )
  );
```

## Fonctions et Triggers

### 1. Fonction de nettoyage automatique

```sql
-- Fonction pour supprimer les validations expirées
CREATE OR REPLACE FUNCTION cleanup_expired_validations()
RETURNS void AS $$
BEGIN
  -- Marquer comme expirées
  UPDATE timesheet_validations
  SET status = 'expired'
  WHERE expires_at < NOW()
  AND status = 'submitted';
  
  -- Supprimer les fichiers Storage après 30 jours
  DELETE FROM storage.objects
  WHERE bucket_id = 'timesheet-pdfs'
  AND created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Planifier l'exécution quotidienne (via pg_cron)
SELECT cron.schedule(
  'cleanup-expired-validations',
  '0 2 * * *', -- 2h du matin chaque jour
  'SELECT cleanup_expired_validations();'
);
```

### 2. Trigger pour historique

```sql
-- Trigger pour enregistrer l'historique
CREATE OR REPLACE FUNCTION record_validation_history()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO validation_history (
      validation_id,
      action,
      performed_by,
      previous_status,
      new_status,
      details
    ) VALUES (
      NEW.id,
      'status_change',
      auth.uid(),
      OLD.status,
      NEW.status,
      jsonb_build_object(
        'validated_at', NEW.validated_at,
        'signed_pdf_url', NEW.signed_pdf_url
      )
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER validation_history_trigger
  AFTER UPDATE ON timesheet_validations
  FOR EACH ROW
  EXECUTE FUNCTION record_validation_history();
```

### 3. Fonction pour obtenir le manager actif

```sql
CREATE OR REPLACE FUNCTION get_active_manager(employee_uuid UUID)
RETURNS UUID AS $$
DECLARE
  manager_uuid UUID;
BEGIN
  SELECT manager_id INTO manager_uuid
  FROM manager_assignments
  WHERE employee_id = employee_uuid
  AND is_active = true
  AND (end_date IS NULL OR end_date >= CURRENT_DATE)
  ORDER BY start_date DESC
  LIMIT 1;
  
  RETURN manager_uuid;
END;
$$ LANGUAGE plpgsql;
```

## Index de performance

```sql
-- Index composites pour requêtes fréquentes
CREATE INDEX idx_validations_manager_pending 
  ON timesheet_validations(manager_id, status) 
  WHERE status = 'submitted';

CREATE INDEX idx_validations_employee_recent 
  ON timesheet_validations(employee_id, submitted_at DESC);

-- Index pour recherche full-text (si nécessaire)
CREATE INDEX idx_feedback_comment_search 
  ON validation_feedback 
  USING gin(to_tsvector('french', general_comment));
```

## Vues matérialisées pour dashboard

```sql
-- Vue pour statistiques manager
CREATE MATERIALIZED VIEW manager_validation_stats AS
SELECT 
  manager_id,
  COUNT(*) FILTER (WHERE status = 'submitted') as pending_count,
  COUNT(*) FILTER (WHERE status = 'validated') as validated_count,
  COUNT(*) FILTER (WHERE status = 'rejected') as rejected_count,
  AVG(EXTRACT(EPOCH FROM (validated_at - submitted_at))/3600) as avg_validation_hours
FROM timesheet_validations
WHERE submitted_at > NOW() - INTERVAL '30 days'
GROUP BY manager_id;

-- Refresh automatique
CREATE OR REPLACE FUNCTION refresh_manager_stats()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY manager_validation_stats;
END;
$$ LANGUAGE plpgsql;

-- Planifier le refresh toutes les heures
SELECT cron.schedule(
  'refresh-manager-stats',
  '0 * * * *',
  'SELECT refresh_manager_stats();'
);
```

## Migration et seed data

```sql
-- Script de migration initial
BEGIN;

-- Créer les tables dans l'ordre
-- ... (toutes les CREATE TABLE ci-dessus)

-- Données de test (développement uniquement)
INSERT INTO organizations (name, domain) VALUES
  ('Avasad', 'avasad.ch'),
  ('Test Company', 'test.com');

-- Créer des utilisateurs de test
INSERT INTO users (email, full_name, organization_id, role) 
SELECT 
  'employee' || i || '@avasad.ch',
  'Employee ' || i,
  (SELECT id FROM organizations WHERE domain = 'avasad.ch'),
  'employee'
FROM generate_series(1, 5) i;

INSERT INTO users (email, full_name, organization_id, role)
VALUES 
  ('manager@avasad.ch', 'Manager Test', 
   (SELECT id FROM organizations WHERE domain = 'avasad.ch'), 'manager');

COMMIT;
```