-- Supprimer les anciennes politiques qui causent la récursion
DROP POLICY IF EXISTS "Allow public read managers" ON public.managers;
DROP POLICY IF EXISTS "Allow public insert managers" ON public.managers;
DROP POLICY IF EXISTS "Allow public update managers" ON public.managers;
DROP POLICY IF EXISTS "Allow public delete managers" ON public.managers;

-- Désactiver temporairement RLS pour corriger
ALTER TABLE public.managers DISABLE ROW LEVEL SECURITY;

-- Réactiver RLS
ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;

-- Créer des politiques simplifiées sans récursion
-- Politique pour lecture publique
CREATE POLICY "managers_select_policy" ON public.managers
  FOR SELECT
  TO PUBLIC
  USING (true);

-- Politique pour insertion publique
CREATE POLICY "managers_insert_policy" ON public.managers
  FOR INSERT
  TO PUBLIC
  WITH CHECK (true);

-- Politique pour mise à jour publique
CREATE POLICY "managers_update_policy" ON public.managers
  FOR UPDATE
  TO PUBLIC
  USING (true)
  WITH CHECK (true);

-- Politique pour suppression publique
CREATE POLICY "managers_delete_policy" ON public.managers
  FOR DELETE
  TO PUBLIC
  USING (true);

-- Vérifier que les politiques sont bien créées
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'managers';