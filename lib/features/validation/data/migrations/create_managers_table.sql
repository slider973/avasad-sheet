-- Table pour stocker les managers disponibles
CREATE TABLE IF NOT EXISTS managers (
  id TEXT PRIMARY KEY,
  company TEXT NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(company, email)
);

-- Index pour améliorer les performances
CREATE INDEX idx_managers_company ON managers(company);

-- RLS policies
ALTER TABLE managers ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre la lecture publique (pas d'auth)
CREATE POLICY "Allow public read" ON managers
  FOR SELECT
  USING (true);

-- Politique pour permettre l'insertion publique (pas d'auth)
CREATE POLICY "Allow public insert" ON managers
  FOR INSERT
  WITH CHECK (true);

-- Politique pour permettre la suppression publique (pas d'auth)
CREATE POLICY "Allow public delete" ON managers
  FOR DELETE
  USING (true);