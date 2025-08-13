-- Solution alternative : Désactiver complètement RLS pour la table managers
-- Utilisez cette migration si la précédente ne fonctionne pas

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "managers_select_policy" ON public.managers;
DROP POLICY IF EXISTS "managers_insert_policy" ON public.managers;
DROP POLICY IF EXISTS "managers_update_policy" ON public.managers;
DROP POLICY IF EXISTS "managers_delete_policy" ON public.managers;

-- Désactiver RLS complètement
ALTER TABLE public.managers DISABLE ROW LEVEL SECURITY;

-- Vérifier que RLS est bien désactivé
SELECT 
  schemaname,
  tablename,
  rowsecurity
FROM pg_tables 
WHERE tablename = 'managers';

-- Note: Sans RLS, la table est accessible publiquement
-- C'est acceptable pour un système sans authentification