-- ============================================================================
-- 00025_fix_postgrest_embed_ambiguity.sql
-- Régression de production introduite par 00023 : plus aucun utilisateur
-- visible sur /admin/users, écran Préférences de l'app mobile cassé.
--
-- Cause : `organizations.default_manager_id REFERENCES profiles(id)` (00023)
-- crée une SECONDE relation entre `profiles` et `organizations`. PostgREST
-- résout les embeds par les clés étrangères : avec deux relations possibles,
-- `profiles?select=*,organizations(name)` devient ambigu et échoue en
-- PGRST201 (« Could not embed because more than one relationship was found »).
-- La requête entière est rejetée -> liste vide côté client.
--
-- Clients concernés (vérifiés) :
--   - timesheet-web : use-users-management.ts:11, user-detail.tsx:93
--   - Flutter       : preferences_bloc.dart:92
--
-- Pourquoi corriger côté base plutôt que côté clients : la désambiguïsation
-- (`organizations!profiles_organization_id_fkey(name)`) supposerait de
-- redéployer TOUS les clients, or les builds iOS sont hors service (compte
-- Codemagic en HTTP 402) et les versions déjà installées resteraient cassées.
-- Une base compatible avec les clients existants prime ici sur la contrainte
-- référentielle.
--
-- Correctif : retirer la contrainte FK (la colonne `default_manager_id` et
-- l'index restent) et reproduire son `ON DELETE SET NULL` par un trigger.
-- L'intégrité à l'écriture reste assurée par `set_organization_manager`, qui
-- vérifie l'existence et l'activité du profil avant de l'enregistrer.
--
-- ⚠️ Ne pas réintroduire de clé étrangère entre `organizations` et `profiles`
-- sans désambiguïser d'abord les embeds de TOUS les clients déployés.
--
-- Migration idempotente.
-- ============================================================================

ALTER TABLE public.organizations
  DROP CONSTRAINT IF EXISTS organizations_default_manager_id_fkey;

COMMENT ON COLUMN public.organizations.default_manager_id IS
  'Manager responsable des relevés d''heures de l''organisation. Les liens '
  'effectifs vivent dans manager_employees (cf. set_organization_manager). '
  'Volontairement SANS clé étrangère vers profiles : une 2e relation '
  'profiles<->organizations rendrait les embeds PostgREST ambigus (PGRST201, '
  'cf. 00025). Le nettoyage est assuré par le trigger ci-dessous.';

-- Équivalent fonctionnel de ON DELETE SET NULL.
CREATE OR REPLACE FUNCTION public.clear_default_manager_on_profile_delete()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.organizations
     SET default_manager_id = NULL
   WHERE default_manager_id = OLD.id;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_clear_default_manager ON public.profiles;
CREATE TRIGGER trg_clear_default_manager
  BEFORE DELETE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.clear_default_manager_on_profile_delete();

-- Filet de sécurité : purge d'éventuelles références orphelines laissées par
-- une suppression survenue pendant que la contrainte était absente.
UPDATE public.organizations o
   SET default_manager_id = NULL
 WHERE o.default_manager_id IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = o.default_manager_id);

-- NB : l'enregistrement dans `public.schema_migrations` se fait manuellement
-- APRÈS application (cf. CLAUDE.md).
