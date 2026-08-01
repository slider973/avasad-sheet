-- ============================================================================
-- 00026_block_self_org_attachment.sql
-- Tenant escape (pentest du 2026-08-01, run /2, finding Critical) : n'importe
-- quel visiteur pouvait créer un compte puis REJOINDRE l'organisation de son
-- choix, et y lire le répertoire des employés.
--
-- Cause : `guard_profile_update` (00021) n'interdisait que le CHANGEMENT
-- d'organisation (`OLD.organization_id IS NOT NULL`). Le PREMIER rattachement
-- `NULL -> <org>` restait libre — c'était le parcours d'onboarding assumé
-- (sélecteur d'organisation à l'inscription). Or le signup est ouvert et
-- auto-confirmé, et `list_child_organizations` (00022) fournit à tout compte
-- authentifié les UUID de toutes les organisations : la chaîne
-- « signup -> PATCH organization_id -> lecture du répertoire » était triviale.
--
-- Portée vérifiée de la fuite : `profiles_select` (emails, noms, rôles,
-- téléphones des membres) et la fiche de l'organisation. Les pointages,
-- absences, anomalies et frais restaient fermés : leurs policies (00008)
-- exigent `is_manager()` ou un lien `manager_employees`, hors de portée d'un
-- simple `employee`.
--
-- Correctif : le rattachement à une organisation devient une décision de
-- l'organisation, jamais de l'utilisateur.
--   1) UPDATE : tout changement de `organization_id` par un non-admin est
--      refusé, y compris depuis NULL.
--   2) INSERT : un utilisateur qui s'auto-insère un profil ne peut se donner
--      ni organisation ni rôle privilégié. Ce chemin n'est pas exploitable
--      aujourd'hui (le profil est déjà créé par `on_auth_user_created` et
--      aucune policy DELETE n'existe sur `profiles`), mais `profiles_insert`
--      autorise `id = auth.uid()` sans contrôle sur ces colonnes : on ferme
--      la porte plutôt que de dépendre de cette conjonction.
--
-- Inchangé : `service_role` (Edge Function `create-user`) et `super_admin`
-- sortent avant toute vérification ; un `org_admin` garde la main sur son
-- périmètre. Créer un compte déjà rattaché, rattacher après coup, changer ou
-- retirer une organisation restent possibles depuis /admin/users.
--
-- ⚠️ Conséquence produit : le sélecteur d'organisation de l'onboarding mobile
-- (onboarding_page.dart, preference_form-v2.dart) échouera désormais avec
-- « Rattachement à une organisation interdit ». C'est voulu — ce sélecteur
-- proposait toutes les organisations actives. Le parcours devient : le compte
-- est créé (ou rattaché) depuis l'admin web, l'employé se connecte.
--
-- Migration idempotente.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) UPDATE : plus d'auto-rattachement, même depuis NULL
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_profile_update()
RETURNS trigger AS $$
DECLARE
  acting_admin boolean;
BEGIN
  -- Edge Functions (create-user, ...) = autorité serveur
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF public.is_super_admin() THEN
    RETURN NEW;
  END IF;

  acting_admin := public.is_org_admin()
                  AND OLD.organization_id = ANY (public.get_my_org_ids());

  -- Le rôle ne se modifie que par un admin
  IF NEW.role IS DISTINCT FROM OLD.role AND NOT acting_admin THEN
    RAISE EXCEPTION 'Modification du role interdite';
  END IF;

  -- L'organisation est décidée par l'organisation, jamais par l'utilisateur :
  -- ni changement, ni premier rattachement depuis NULL (00026).
  IF NEW.organization_id IS DISTINCT FROM OLD.organization_id
     AND NOT acting_admin THEN
    RAISE EXCEPTION 'Rattachement à une organisation interdit : contactez votre administrateur';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS trg_guard_profile_update ON public.profiles;
CREATE TRIGGER trg_guard_profile_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.guard_profile_update();

-- ---------------------------------------------------------------------------
-- 2) INSERT : pas d'organisation ni de rôle privilégié en self-service
--
-- `handle_new_user` (trigger sur auth.users) insère le profil avec
-- organization_id NULL et role 'employee' : il satisfait ces conditions et
-- n'est donc pas bloqué, y compris pendant le signup où auth.uid() est NULL.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.guard_profile_insert()
RETURNS trigger AS $$
BEGIN
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  IF public.is_super_admin()
     OR (public.is_org_admin() AND NEW.organization_id = ANY (public.get_my_org_ids())) THEN
    RETURN NEW;
  END IF;

  IF NEW.organization_id IS NOT NULL THEN
    RAISE EXCEPTION 'Rattachement à une organisation interdit : contactez votre administrateur';
  END IF;

  IF NEW.role IS DISTINCT FROM 'employee' THEN
    RAISE EXCEPTION 'Attribution du role interdite';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS trg_guard_profile_insert ON public.profiles;
CREATE TRIGGER trg_guard_profile_insert
  BEFORE INSERT ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.guard_profile_insert();

-- NB : l'enregistrement dans `public.schema_migrations` se fait manuellement
-- APRÈS application (cf. CLAUDE.md).
