-- Migration pour créer la table managers (système sans authentification)
-- Cette table est séparée de la table users car elle ne nécessite pas d'authentification

-- Créer la table des managers
CREATE TABLE IF NOT EXISTS public.managers (
  id TEXT PRIMARY KEY,
  company TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT unique_manager_per_company UNIQUE(company, email)
);

-- Créer les index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_managers_company ON public.managers(company);
CREATE INDEX IF NOT EXISTS idx_managers_email ON public.managers(email);

-- Activer Row Level Security
ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre la lecture publique (pas d'auth requis)
CREATE POLICY "Allow public read managers" ON public.managers
  FOR SELECT
  USING (true);

-- Politique pour permettre l'insertion publique (pas d'auth requis)
CREATE POLICY "Allow public insert managers" ON public.managers
  FOR INSERT
  WITH CHECK (true);

-- Politique pour permettre la mise à jour publique (pas d'auth requis)
CREATE POLICY "Allow public update managers" ON public.managers
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

-- Politique pour permettre la suppression publique (pas d'auth requis)
CREATE POLICY "Allow public delete managers" ON public.managers
  FOR DELETE
  USING (true);

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER update_managers_updated_at
  BEFORE UPDATE ON public.managers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Fonction pour récupérer les managers d'une entreprise
CREATE OR REPLACE FUNCTION get_managers_by_company(company_name TEXT)
RETURNS TABLE(
  id TEXT,
  email TEXT,
  full_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.email,
    m.first_name || ' ' || m.last_name as full_name
  FROM public.managers m
  WHERE m.company = company_name
  ORDER BY m.last_name, m.first_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Insérer quelques managers de test (optionnel, commentez si non désiré)
/*
INSERT INTO public.managers (id, company, first_name, last_name, email) VALUES
  ('heytalent_jean_dupont', 'HeyTalent', 'Jean', 'Dupont', 'jean.dupont@heytalent.ch'),
  ('heytalent_marie_martin', 'HeyTalent', 'Marie', 'Martin', 'marie.martin@heytalent.ch')
ON CONFLICT (company, email) DO NOTHING;
*/

-- Commentaire sur la table
COMMENT ON TABLE public.managers IS 'Table des managers pour le système de validation sans authentification';
COMMENT ON COLUMN public.managers.id IS 'Identifiant unique format: company_firstname_lastname en minuscules';
COMMENT ON COLUMN public.managers.company IS 'Nom de l''entreprise (doit être identique pour tous les utilisateurs d''une même entreprise)';