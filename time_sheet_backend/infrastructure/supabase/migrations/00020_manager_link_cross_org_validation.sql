-- ============================================================================
-- 00020_manager_link_cross_org_validation.sql
-- Découpler l'AUTORISATION de validation de la hiérarchie d'organisations.
--
-- Contexte : le droit de valider repose déjà entièrement sur `manager_employees`
-- (RLS 00008/00019 et bucket PowerSync `manager_data` n'appliquent AUCUN filtre
-- d'organisation sur cette branche). La hiérarchie d'orgs n'intervient qu'à la
-- SOUMISSION, en deux endroits :
--   1) `get_managers_for_employee` (00019) — alimente le sélecteur de manager
--   2) l'Edge Function `create-validation` — recontrôle côté serveur
-- Or `organizations.parent_id` est un parent UNIQUE + trigger 1 niveau
-- (00006) : un manager hors de la branche d'ancêtres de l'employé est donc
-- refusé, même s'il lui est explicitement rattaché.
--
-- Cas réel (2026-07-30) : Sovattha (manager) doit valider un employé qui n'est
-- pas dans son org ni dans une org ancêtre.
--
-- Choix d'architecture : plutôt que de rendre les orgs multi-parents (DAG),
-- qui exposerait TOUS les employés d'une org fille aux org_admin de CHAQUE org
-- mère, on autorise le rattachement explicite et nominatif via
-- `manager_employees`. Granularité par personne, pas par organisation.
--
-- Correctifs :
--   1) get_managers_for_employee : orgs ancêtres OU lien manager_employees
--   2) manager_employees_insert : un org_admin peut rattacher un employé de
--      son périmètre à un manager EXTERNE (amorçage du lien — le trigger
--      `link_manager_on_validation` (00015) ne le crée qu'APRÈS une première
--      validation, d'où un problème d'œuf et de poule).
--
-- Companion changes (hors SQL) :
--   - infrastructure/supabase/functions/create-validation/index.ts
--   - infrastructure/powersync/powersync.yaml (bucket manager_data : profiles)
--
-- Migration idempotente.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) get_managers_for_employee : + branche lien manager_employees explicite
--    Garde-fou 00017/00019 conservé : l'appelant doit être la cible ou de son
--    périmètre d'org.
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
    AND (
      -- Modèle historique : manager dans l'org de l'employé ou une org ancêtre
      p.organization_id IN (SELECT oa.id FROM org_ancestors oa)
      -- Nouveau : manager explicitement rattaché, quelle que soit son org
      OR EXISTS (
        SELECT 1 FROM public.manager_employees me
        WHERE me.manager_id = p.id AND me.employee_id = employee_user_id
      )
    )
  ORDER BY p.first_name, p.last_name;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ---------------------------------------------------------------------------
-- 2) manager_employees_insert : amorçage d'un lien INTER-ORGS par un org_admin
--
-- Avant (00004) : l'org_admin devait avoir les DEUX parties dans son périmètre
--   (is_same_org(manager_id) AND is_same_org(employee_id)) -> impossible de
--   déléguer la validation d'un de ses employés à un manager externe.
-- Après : il lui suffit d'avoir l'EMPLOYÉ dans son périmètre. Sémantique :
--   « je délègue la validation de MON employé à ce manager ».
--
-- ⚠️ La 3e branche (manager/admin s'auto-rattachant : `manager_id = auth.uid()`)
-- est reprise telle quelle depuis 00004. Elle n'a jamais eu de contrôle d'org :
-- tout manager peut déjà se rattacher n'importe quel employé de la base et lire
-- ses données via la branche `manager_employees` des policies 00008. C'est un
-- vecteur d'élévation de privilèges PRÉEXISTANT, non introduit ici — à durcir
-- dans une migration dédiée (ex. restreindre au périmètre d'org du manager, ou
-- réserver la création du lien au trigger + org_admin).
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "manager_employees_insert" ON public.manager_employees;
CREATE POLICY "manager_employees_insert" ON public.manager_employees
  FOR INSERT WITH CHECK (
    public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(employee_id))
    OR (public.get_my_role() IN ('manager', 'admin') AND manager_id = auth.uid())
  );

-- NB : l'enregistrement dans `public.schema_migrations` se fait manuellement
-- APRÈS application (cf. CLAUDE.md). Cette table est partagée avec les
-- migrations Rails de DocuSeal — ne pas y insérer depuis le script.
