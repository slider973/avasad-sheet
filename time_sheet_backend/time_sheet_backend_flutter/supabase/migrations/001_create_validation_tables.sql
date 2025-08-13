-- Create organizations table
CREATE TABLE IF NOT EXISTS organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create users table with organization and role
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  organization_id UUID REFERENCES organizations(id),
  role TEXT NOT NULL DEFAULT 'employee' CHECK (role IN ('employee', 'manager', 'admin')),
  fcm_token TEXT,
  fcm_updated_at TIMESTAMPTZ,
  platform TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create validation_requests table
CREATE TABLE IF NOT EXISTS validation_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES organizations(id),
  employee_id UUID NOT NULL REFERENCES users(id),
  manager_id UUID NOT NULL REFERENCES users(id),
  
  -- Période de validation
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  
  -- Métadonnées du PDF
  pdf_path TEXT NOT NULL, -- Chemin dans Supabase Storage
  pdf_size_bytes BIGINT NOT NULL,
  pdf_hash TEXT NOT NULL,
  
  -- Statut et workflow
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  status_changed_at TIMESTAMPTZ,
  
  -- Feedback du manager
  manager_comment TEXT,
  manager_signature TEXT, -- Base64 de la signature
  validated_at TIMESTAMPTZ,
  
  -- Métadonnées
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '7 days'),
  
  -- Contraintes
  CONSTRAINT unique_period_per_employee UNIQUE (employee_id, period_start, period_end)
);

-- Create notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  validation_request_id UUID REFERENCES validation_requests(id),
  
  type TEXT NOT NULL CHECK (type IN ('validation_request', 'validation_feedback', 'reminder')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  
  read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create sync_queue table for offline support
CREATE TABLE IF NOT EXISTS sync_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  action TEXT NOT NULL CHECK (action IN ('create_validation', 'update_validation', 'delete_validation')),
  payload JSONB NOT NULL,
  
  synced BOOLEAN DEFAULT FALSE,
  synced_at TIMESTAMPTZ,
  error TEXT,
  retry_count INT DEFAULT 0,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_validation_requests_employee ON validation_requests(employee_id);
CREATE INDEX idx_validation_requests_manager ON validation_requests(manager_id);
CREATE INDEX idx_validation_requests_status ON validation_requests(status);
CREATE INDEX idx_validation_requests_period ON validation_requests(period_start, period_end);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, read) WHERE read = FALSE;
CREATE INDEX idx_sync_queue_unsynced ON sync_queue(user_id, synced) WHERE synced = FALSE;

-- Row Level Security (RLS)
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE validation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_queue ENABLE ROW LEVEL SECURITY;

-- Policies for organizations
CREATE POLICY "Users can view their organization"
  ON organizations FOR SELECT
  USING (id IN (
    SELECT organization_id FROM users WHERE id = auth.uid()
  ));

-- Policies for users
CREATE POLICY "Users can view users in their organization"
  ON users FOR SELECT
  USING (
    organization_id IN (
      SELECT organization_id FROM users WHERE id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Policies for validation_requests
CREATE POLICY "Employees can view their own validations"
  ON validation_requests FOR SELECT
  USING (employee_id = auth.uid());

CREATE POLICY "Managers can view validations they manage"
  ON validation_requests FOR SELECT
  USING (manager_id = auth.uid());

CREATE POLICY "Employees can create validation requests"
  ON validation_requests FOR INSERT
  WITH CHECK (employee_id = auth.uid() AND status = 'pending');

CREATE POLICY "Managers can update validations they manage"
  ON validation_requests FOR UPDATE
  USING (manager_id = auth.uid())
  WITH CHECK (manager_id = auth.uid());

-- Policies for notifications
CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Policies for sync_queue
CREATE POLICY "Users can manage their own sync queue"
  ON sync_queue FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Functions
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER update_organizations_updated_at
  BEFORE UPDATE ON organizations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_validation_requests_updated_at
  BEFORE UPDATE ON validation_requests
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Function to clean expired validation requests
CREATE OR REPLACE FUNCTION clean_expired_validations()
RETURNS void AS $$
BEGIN
  DELETE FROM validation_requests
  WHERE expires_at < NOW()
  AND status = 'pending';
END;
$$ LANGUAGE plpgsql;

-- Function to get managers for an employee
CREATE OR REPLACE FUNCTION get_managers_for_employee(employee_uuid UUID)
RETURNS TABLE(id UUID, email TEXT) AS $$
BEGIN
  RETURN QUERY
  SELECT u.id, u.email
  FROM users u
  WHERE u.organization_id = (
    SELECT organization_id FROM users WHERE id = employee_uuid
  )
  AND u.role IN ('manager', 'admin')
  AND u.id != employee_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;