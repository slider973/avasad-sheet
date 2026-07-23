-- ============================================================================
-- 00019_profiles_manager_link_and_ancestor_orgs.sql
-- Régression du durcissement 00018 : la suppression (justifiée) de la policy
-- legacy `profiles_select_all USING (true)` a privé les managers INTER-ORGS
-- de la lecture des profils de leur équipe. Modèle réel du projet : le
-- manager vit dans l'org MÈRE (ex. Sonrysa) et ses employés dans l'org
-- FILLE (ex. Avasad), reliés par `manager_employees`.
--
-- Symptôme (2026-07-24) : interface web manager vide pour Hermance
-- (profils de l'équipe -> 0 ligne, données équipe visibles mais anonymes).
--
-- Correctifs :
--   1) profiles_select : + lecture via lien manager_employees, dans les
--      DEUX sens (le manager voit ses employés liés, l'employé voit son
--      manager lié) — même modèle que timesheet/absences/anomalies (00008).
--   2) get_managers_for_employee : proposer les managers de l'org de
--      l'employé ET de ses orgs ANCÊTRES (hiérarchie 00006), au lieu de la
--      même org strictement (00017 était trop restrictif pour ce modèle).
--
-- Migration idempotente.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) profiles_select : branche manager_employees bidirectionnelle
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (
    public.is_super_admin()
    OR id = auth.uid()
    OR organization_id = ANY (public.get_my_org_ids())
    -- Manager -> profils de ses employés liés (inter-orgs inclus)
    OR EXISTS (
      SELECT 1 FROM public.manager_employees me
      WHERE me.manager_id = auth.uid() AND me.employee_id = profiles.id
    )
    -- Employé -> profil de ses managers liés (inter-orgs inclus)
    OR EXISTS (
      SELECT 1 FROM public.manager_employees me
      WHERE me.employee_id = auth.uid() AND me.manager_id = profiles.id
    )
  );

-- ---------------------------------------------------------------------------
-- 2) get_managers_for_employee : org de l'employé + orgs ancêtres
--    (garde-fou 00017 conservé : l'appelant doit être de l'org de la cible
--    ou être la cible elle-même)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_managers_for_employee(employee_user_id UUID)
RETURNS TABLE(id UUID, email TEXT, first_name TEXT, last_name TEXT) AS $$
  WITH RECURSIVE org_ancestors AS (
    SELECT o.id, o.parent_id
    FROM public.organizations o
    WHERE o.id = (SELECT ep.organization_id FROM public.profiles ep
                  WHERE ep.id = employee_user_id)
    UNION
    SELECT o.id, o.parent_id
    FROM public.organizations o
    JOIN org_ancestors a ON o.id = a.parent_id
  )
  SELECT p.id, p.email, p.first_name, p.last_name
  FROM public.profiles p
  WHERE (auth.uid() = employee_user_id OR public.is_same_org(employee_user_id))
    AND p.role IN ('manager', 'admin', 'org_admin', 'super_admin')
    AND p.is_active = true
    AND p.organization_id IN (SELECT oa.id FROM org_ancestors oa)
  ORDER BY p.first_name, p.last_name;
$$ LANGUAGE sql SECURITY DEFINER STABLE;
