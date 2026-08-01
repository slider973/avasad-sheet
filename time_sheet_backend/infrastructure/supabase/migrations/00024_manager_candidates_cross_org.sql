-- ============================================================================
-- 00024_manager_candidates_cross_org.sql
-- Aligner `list_manager_candidates` (00023) sur ce que
-- `set_organization_manager` autorise déjà.
--
-- Incohérence constatée le 2026-08-01 :
--   - `set_organization_manager` n'impose la contrainte « le manager doit
--     appartenir à votre organisation » qu'aux **org_admin**. Un super_admin
--     peut donc désigner n'importe quel manager, quelle que soit son org —
--     c'est le prolongement naturel de 00020 (le droit de valider est
--     nominatif, porté par `manager_employees`, pas par la hiérarchie d'orgs).
--   - `list_manager_candidates` ne propose que les membres de l'org, de ses
--     ancêtres et de ses descendants. Le sélecteur de l'écran admin est donc
--     plus restrictif que l'écriture : l'affectation légitime est possible en
--     SQL mais impossible depuis l'interface.
--
-- Cas réel : « interiman » est une organisation RACINE isolée (ni parent, ni
-- enfant, aucun manager). Son premier employé doit être validé par Sovattha,
-- manager d'Avasad. Scope d'origine = interiman seule -> liste vide, alors
-- que la RPC d'écriture accepterait l'affectation.
--
-- Correctif : pour un super_admin, proposer EN PLUS tous les profils actifs
-- ayant déjà un rôle de management, quelle que soit leur organisation.
--   - hors scope, on ne propose que des managers DÉJÀ en poste : la promotion
--     implicite `employee -> manager` de `set_organization_manager` reste
--     réservée au périmètre de l'organisation, sinon le sélecteur listerait
--     toute la base et un clic de trop promouvrait un employé étranger.
--   - un org_admin garde exactement le scope de 00023, cohérent avec le
--     garde-fou de `set_organization_manager` qui refuserait tout le reste.
--
-- Les candidats hors scope sont triés en dernier ; l'écran affiche déjà
-- « Prénom Nom (Organisation) » (organization-detail.tsx:539), donc aucune
-- modification frontend n'est nécessaire pour lever l'ambiguïté.
--
-- Signature et type de retour inchangés (CREATE OR REPLACE suffit, les grants
-- de 00023 restent valides). Migration idempotente.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.list_manager_candidates(p_org_id UUID)
RETURNS TABLE(
  id UUID, email TEXT, first_name TEXT, last_name TEXT,
  role TEXT, organization_id UUID, organization_name TEXT
) AS $$
  WITH RECURSIVE ancestors AS (
    SELECT o.id, o.parent_id FROM public.organizations o WHERE o.id = p_org_id
    UNION
    SELECT o.id, o.parent_id
    FROM public.organizations o JOIN ancestors a ON o.id = a.parent_id
  ), scope AS (
    SELECT a.id FROM ancestors a
    UNION
    SELECT d.id FROM public.get_org_descendants(p_org_id) d
  )
  SELECT p.id, p.email, p.first_name, p.last_name, p.role,
         p.organization_id, o.name
  FROM public.profiles p
  LEFT JOIN public.organizations o ON o.id = p.organization_id
  WHERE public.can_admin_organization(p_org_id)
    AND p.is_active = true
    AND (
      p.organization_id IN (SELECT s.id FROM scope s)
      -- Nouveau : managers hors hiérarchie, réservé au super_admin
      OR (
        public.is_super_admin()
        AND p.role IN ('manager', 'admin', 'org_admin', 'super_admin')
      )
    )
  ORDER BY
    -- COALESCE : un profil sans organisation (super_admin global) donne NULL,
    -- que `DESC` remonterait en tête de liste.
    COALESCE(p.organization_id IN (SELECT s.id FROM scope s), false) DESC,
    o.name NULLS LAST, p.last_name, p.first_name;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- NB : l'enregistrement dans `public.schema_migrations` se fait manuellement
-- APRÈS application (cf. CLAUDE.md).
