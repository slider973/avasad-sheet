-- ============================================================================
-- 00023_org_settings_and_manager.sql
--
-- Paramétrage d'une organisation par un super_admin (ou l'org_admin de l'org) :
--   1) Colonnes de configuration : logo, personne de contact (prénom/nom),
--      email/téléphone de contact, adresse, manager responsable.
--   2) Bucket storage `org-logos` (lecture publique, écriture réservée aux
--      admins de l'org) — le logo est affiché dans l'app web ET incrusté dans
--      les PDF de relevé d'heures, qui utilisaient jusqu'ici un asset Flutter
--      codé en dur (`assets/images/logo-sonrysa.png`).
--   3) RPC `set_organization_manager()` / `clear_organization_manager()` :
--      affecte un manager responsable à une organisation. L'affectation
--      matérialise les liens `manager_employees` vers tous les employés actifs
--      de l'org (et de ses sous-organisations si demandé). C'est ce lien —
--      et non la hiérarchie d'orgs — qui donne le droit de voir les pointages,
--      de valider et de signer (cf. 00019/00020 et create-validation).
--
-- Migration idempotente.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Colonnes de paramétrage de l'organisation
-- ---------------------------------------------------------------------------
ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS logo_url           TEXT,
  ADD COLUMN IF NOT EXISTS contact_first_name TEXT,
  ADD COLUMN IF NOT EXISTS contact_last_name  TEXT,
  ADD COLUMN IF NOT EXISTS contact_email      TEXT,
  ADD COLUMN IF NOT EXISTS contact_phone      TEXT,
  ADD COLUMN IF NOT EXISTS address            TEXT,
  ADD COLUMN IF NOT EXISTS default_manager_id UUID
    REFERENCES public.profiles(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.organizations.logo_url IS
  'URL publique du logo (bucket org-logos). Incrusté dans les PDF de relevé.';
COMMENT ON COLUMN public.organizations.contact_first_name IS
  'Prénom de la personne de contact / responsable de l''organisation.';
COMMENT ON COLUMN public.organizations.contact_last_name IS
  'Nom de la personne de contact / responsable de l''organisation.';
COMMENT ON COLUMN public.organizations.default_manager_id IS
  'Manager responsable des relevés d''heures de l''organisation. Les liens '
  'effectifs vivent dans manager_employees (cf. set_organization_manager).';

CREATE INDEX IF NOT EXISTS idx_organizations_default_manager
  ON public.organizations(default_manager_id);

-- ---------------------------------------------------------------------------
-- 2) Helpers de droits
-- ---------------------------------------------------------------------------

-- Qui peut administrer une organisation donnée : le super_admin, ou
-- l'org_admin de CETTE organisation.
CREATE OR REPLACE FUNCTION public.can_admin_organization(p_org_id UUID)
RETURNS BOOLEAN AS $$
  SELECT public.is_super_admin()
      OR (public.is_org_admin() AND p_org_id = public.get_my_org_id());
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Variante « chemin storage » : le 1er segment du chemin est l'UUID de l'org.
-- Le cast est protégé pour qu'un chemin non-UUID renvoie false au lieu de
-- faire échouer l'évaluation de la policy.
CREATE OR REPLACE FUNCTION public.can_admin_org_folder(p_folder TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  v_org_id UUID;
BEGIN
  BEGIN
    v_org_id := p_folder::UUID;
  EXCEPTION WHEN others THEN
    RETURN false;
  END;
  RETURN public.can_admin_organization(v_org_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Descendants d'une organisation (elle-même incluse).
CREATE OR REPLACE FUNCTION public.get_org_descendants(p_org_id UUID)
RETURNS TABLE(id UUID) AS $$
  WITH RECURSIVE tree AS (
    SELECT o.id FROM public.organizations o WHERE o.id = p_org_id
    UNION
    SELECT o.id FROM public.organizations o JOIN tree t ON o.parent_id = t.id
  )
  SELECT t.id FROM tree t;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ---------------------------------------------------------------------------
-- 3) Bucket `org-logos`
--    Lecture publique assumée : un logo d'entreprise n'est pas une donnée
--    sensible, et le rendre public évite de signer une URL à chaque
--    génération de PDF (app mobile hors ligne incluse).
--    Écriture/suppression : admins de l'organisation uniquement.
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('org-logos', 'org-logos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Garde-fous serveur (2 Mo, PNG/JPEG) : PNG et JPEG sont les seuls formats que
-- le générateur de PDF Flutter (`pw.MemoryImage`) sait décoder. Appliqué
-- seulement si la version de storage embarque ces colonnes.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'storage' AND table_name = 'buckets'
      AND column_name = 'file_size_limit'
  ) THEN
    UPDATE storage.buckets
       SET file_size_limit = 2097152,
           allowed_mime_types = ARRAY['image/png', 'image/jpeg']
     WHERE id = 'org-logos';
  END IF;
END $$;

DROP POLICY IF EXISTS "org_logos_read"   ON storage.objects;
DROP POLICY IF EXISTS "org_logos_insert" ON storage.objects;
DROP POLICY IF EXISTS "org_logos_update" ON storage.objects;
DROP POLICY IF EXISTS "org_logos_delete" ON storage.objects;

CREATE POLICY "org_logos_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'org-logos');

CREATE POLICY "org_logos_insert" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'org-logos'
    AND public.can_admin_org_folder((storage.foldername(name))[1])
  );

CREATE POLICY "org_logos_update" ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'org-logos'
    AND public.can_admin_org_folder((storage.foldername(name))[1])
  );

CREATE POLICY "org_logos_delete" ON storage.objects FOR DELETE
  USING (
    bucket_id = 'org-logos'
    AND public.can_admin_org_folder((storage.foldername(name))[1])
  );

-- ---------------------------------------------------------------------------
-- 4) Affectation du manager responsable
--
--    Effets de `set_organization_manager` :
--      - promotion du profil cible au rôle `manager` s'il est encore `employee`
--      - `organizations.default_manager_id` = le manager (mémorise le choix,
--        sert à pré-sélectionner le destinataire d'une demande de validation)
--      - création des liens `manager_employees` vers tous les employés actifs
--        de l'org (et de ses descendants si p_include_descendants).
--        Ce lien est ce qui ouvre : sync PowerSync manager_data, lecture des
--        pointages/absences/anomalies (00008/00019), droit de valider et de
--        signer même hors hiérarchie d'orgs (00020).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_organization_manager(
  p_org_id               UUID,
  p_manager_id           UUID,
  p_include_descendants  BOOLEAN DEFAULT true
) RETURNS INTEGER AS $$
DECLARE
  v_manager   public.profiles%ROWTYPE;
  v_org_count INTEGER;
  v_linked    INTEGER;
BEGIN
  IF NOT public.can_admin_organization(p_org_id) THEN
    RAISE EXCEPTION 'Droits insuffisants pour administrer cette organisation'
      USING ERRCODE = '42501';
  END IF;

  SELECT COUNT(*) INTO v_org_count
  FROM public.organizations WHERE id = p_org_id;
  IF v_org_count = 0 THEN
    RAISE EXCEPTION 'Organisation introuvable' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_manager FROM public.profiles WHERE id = p_manager_id;
  IF v_manager.id IS NULL THEN
    RAISE EXCEPTION 'Profil manager introuvable' USING ERRCODE = 'P0002';
  END IF;
  IF v_manager.is_active IS NOT TRUE THEN
    RAISE EXCEPTION 'Ce profil est désactivé' USING ERRCODE = '22023';
  END IF;

  -- Un org_admin ne peut désigner qu'un manager de son propre périmètre.
  IF NOT public.is_super_admin()
     AND v_manager.organization_id IS DISTINCT FROM public.get_my_org_id() THEN
    RAISE EXCEPTION 'Le manager doit appartenir à votre organisation'
      USING ERRCODE = '42501';
  END IF;

  IF v_manager.role = 'employee' THEN
    UPDATE public.profiles SET role = 'manager' WHERE id = p_manager_id;
  END IF;

  UPDATE public.organizations
    SET default_manager_id = p_manager_id
    WHERE id = p_org_id;

  WITH target_orgs AS (
    SELECT d.id FROM public.get_org_descendants(p_org_id) d
    WHERE p_include_descendants OR d.id = p_org_id
  ), inserted AS (
    INSERT INTO public.manager_employees (manager_id, employee_id)
    SELECT p_manager_id, p.id
    FROM public.profiles p
    WHERE p.organization_id IN (SELECT id FROM target_orgs)
      AND p.id <> p_manager_id
      AND p.is_active = true
    ON CONFLICT (manager_id, employee_id) DO NOTHING
    RETURNING 1
  )
  SELECT COUNT(*)::INTEGER INTO v_linked FROM inserted;

  RETURN v_linked;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Retrait du manager responsable : efface `default_manager_id` et supprime les
-- liens `manager_employees` de ce manager sur le périmètre de l'organisation.
CREATE OR REPLACE FUNCTION public.clear_organization_manager(
  p_org_id              UUID,
  p_include_descendants BOOLEAN DEFAULT true
) RETURNS INTEGER AS $$
DECLARE
  v_manager_id UUID;
  v_removed    INTEGER;
BEGIN
  IF NOT public.can_admin_organization(p_org_id) THEN
    RAISE EXCEPTION 'Droits insuffisants pour administrer cette organisation'
      USING ERRCODE = '42501';
  END IF;

  SELECT default_manager_id INTO v_manager_id
  FROM public.organizations WHERE id = p_org_id;

  IF v_manager_id IS NULL THEN
    RETURN 0;
  END IF;

  WITH target_orgs AS (
    SELECT d.id FROM public.get_org_descendants(p_org_id) d
    WHERE p_include_descendants OR d.id = p_org_id
  ), deleted AS (
    DELETE FROM public.manager_employees me
    USING public.profiles p
    WHERE me.manager_id = v_manager_id
      AND me.employee_id = p.id
      AND p.organization_id IN (SELECT id FROM target_orgs)
    RETURNING 1
  )
  SELECT COUNT(*)::INTEGER INTO v_removed FROM deleted;

  UPDATE public.organizations
    SET default_manager_id = NULL
    WHERE id = p_org_id;

  RETURN v_removed;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Candidats manager pour une organisation : membres de l'org, de ses orgs
-- ANCÊTRES (modèle réel : manager dans l'org mère) et de ses descendants.
-- Réservé aux admins de l'organisation.
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
    AND p.organization_id IN (SELECT id FROM scope)
  ORDER BY p.last_name, p.first_name;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ---------------------------------------------------------------------------
-- 5) Grants — authenticated uniquement (aligné sur le durcissement 00021)
-- ---------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.can_admin_organization(UUID)          FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.can_admin_org_folder(TEXT)            FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.get_org_descendants(UUID)             FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_organization_manager(UUID, UUID, BOOLEAN)   FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.clear_organization_manager(UUID, BOOLEAN)       FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.list_manager_candidates(UUID)         FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.can_admin_organization(UUID)        TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_admin_org_folder(TEXT)          TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_org_descendants(UUID)           TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_organization_manager(UUID, UUID, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.clear_organization_manager(UUID, BOOLEAN)     TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_manager_candidates(UUID)       TO authenticated;

-- `can_admin_org_folder` est appelée depuis les policies storage, évaluées
-- sous le rôle de la requête : le grant à authenticated suffit.

-- NB : l'enregistrement dans `public.schema_migrations` se fait manuellement
-- APRÈS application (cf. CLAUDE.md).
