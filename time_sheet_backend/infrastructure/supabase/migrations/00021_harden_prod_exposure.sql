-- ============================================================================
-- 00021_harden_prod_exposure.sql
-- Remédiation de l'exposition critique constatée le 2026-07-31 (pentest
-- autorisé, rapport ~/Documents/pentest/timesheet.staticflow.ch/1/report.md)
-- et vérifiée indépendamment le 2026-08-01.
--
-- CONSTAT : 40 tables sur 51 du schéma `public` n'ont pas de RLS et sont
-- grantées à `anon` ET `authenticated` via PostgREST. Cause racine : DocuSeal
-- (Rails) a été installé dans la MÊME base et le MÊME schéma que Time Sheet.
--
-- Trois chemins de compromission totale, indépendants :
--   1) anon -> lecture/écriture directe sur les 40 tables (PoC du pentest :
--      INSERT d'un compte `role: admin` dans public.users)
--   2) signup instantané (DISABLE_SIGNUP=false + MAILER_AUTOCONFIRM=true)
--      -> INSERT dans `manager_employees` (sans RLS) -> lecture des pointages
--      de n'importe qui À TRAVERS les policies légitimes de 00008, qui
--      s'appuient sur cette table comme ancre de confiance
--   3) signup -> UPDATE profiles SET role='super_admin' WHERE id=auth.uid()
--      (`profiles_update` n'a pas de WITH CHECK, aucun trigger ne protège
--      la colonne `role`)
--
-- ⚠️ `00002_rls_policies.sql` l.16-17 active pourtant RLS sur `organizations`
-- et `manager_employees`. Elle est OFF en prod alors que les 9 autres tables
-- du même bloc l'ont : ces deux tables ont été droppées/recréées après coup.
-- Le repo ne décrit donc PAS l'état réel de la prod.
--
-- Migration idempotente. Ne touche pas aux tables DocuSeal elles-mêmes
-- (aucun ENABLE RLS dessus) : on retire seulement leur exposition PostgREST,
-- DocuSeal se connectant avec son propre rôle.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Chemin #1 : retirer l'exposition PostgREST des tables sans RLS
--
-- Dynamique plutôt que codé en dur : toute table de `public` sans RLS n'a
-- rien à faire derrière PostgREST. Les 11 tables Time Sheet protégées par RLS
-- ne sont pas touchées ; `organizations` et `manager_employees` sont exclues
-- ici car le point 2 leur active RLS (l'app en a légitimement besoin).
-- ---------------------------------------------------------------------------
DO $$
DECLARE
  t record;
  n int := 0;
BEGIN
  FOR t IN
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace ns ON ns.oid = c.relnamespace
    WHERE ns.nspname = 'public'
      AND c.relkind = 'r'
      AND c.relrowsecurity = false
      AND c.relname NOT IN ('organizations', 'manager_employees')
  LOOP
    EXECUTE format('REVOKE ALL ON public.%I FROM anon, authenticated', t.relname);
    n := n + 1;
  END LOOP;
  RAISE NOTICE 'REVOKE applique sur % tables sans RLS', n;
END $$;

-- Empêcher toute NOUVELLE table (migration Rails/DocuSeal future) d'être
-- exposée automatiquement.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM authenticated;

-- ---------------------------------------------------------------------------
-- 2) Chemin #2 : réactiver RLS sur les deux tables Time Sheet qui l'ont perdu.
--    Les policies existent déjà (00002/00004/00006/00020) et redeviennent
--    actives du seul fait de l'ENABLE.
-- ---------------------------------------------------------------------------
ALTER TABLE public.organizations     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manager_employees ENABLE ROW LEVEL SECURITY;

-- Régression attendue sinon : `orgs_select` limite aux orgs de
-- `get_my_org_ids()`, or un manager INTER-ORGS (Hermance dans Sonrysa, équipe
-- dans Avasad) ne pourrait plus lire l'org de ses employés — cassant
-- validation_repository_supabase_impl.dart:469/477. On ajoute la même branche
-- `manager_employees` que profiles_select (00019).
DROP POLICY IF EXISTS "orgs_select" ON public.organizations;
CREATE POLICY "orgs_select" ON public.organizations
  FOR SELECT USING (
    public.is_super_admin()
    OR id = ANY (public.get_my_org_ids())
    -- org des personnes que je manage / qui me managent
    OR EXISTS (
      SELECT 1
      FROM public.profiles p
      JOIN public.manager_employees me
        ON (me.employee_id = p.id AND me.manager_id = auth.uid())
        OR (me.manager_id  = p.id AND me.employee_id = auth.uid())
      WHERE p.organization_id = organizations.id
    )
  );

-- ---------------------------------------------------------------------------
-- 3) Chemin #3 : garde-fou sur les colonnes porteuses de privilèges.
--
-- `profiles_update` n'a qu'un USING (pas de WITH CHECK) et RLS ne permet pas
-- de comparer à OLD -> il faut un trigger, même patron que
-- `guard_validation_update` (00015).
--
-- ⚠️ PAS de `REVOKE UPDATE (role)` : sous Supabase, TOUT utilisateur connecté
-- est le rôle Postgres `authenticated` (super_admin est applicatif, pas un
-- rôle DB). Un REVOKE casserait l'écran d'admin web, qui fait un
-- `.update(updates)` générique (use-users-management.ts:59). Le trigger, lui,
-- sait distinguer les admins.
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

  -- L'organisation se renseigne UNE FOIS (onboarding : NULL au départ, cf.
  -- preferences_bloc.dart:228), elle ne se change plus ensuite.
  IF NEW.organization_id IS DISTINCT FROM OLD.organization_id
     AND NOT acting_admin
     AND OLD.organization_id IS NOT NULL THEN
    RAISE EXCEPTION 'Changement d''organisation interdit';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

DROP TRIGGER IF EXISTS trg_guard_profile_update ON public.profiles;
CREATE TRIGGER trg_guard_profile_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.guard_profile_update();

-- ---------------------------------------------------------------------------
-- NB : l'enregistrement dans `public.schema_migrations` se fait manuellement
-- APRÈS application (cf. CLAUDE.md) — table partagée avec les migrations Rails.
--
-- RESTE À FAIRE hors SQL (voir rapport de pentest) :
--   - rotation du mot de passe admin DocuSeal (hash bcrypt exfiltré)
--   - régénération des access_tokens applicatifs, rotation clé lockbox
--   - audit des logs PostgREST/Postgres
--   - P2 : sortir DocuSeal du schéma `public` et de PGRST_DB_SCHEMAS
-- ---------------------------------------------------------------------------
