-- ============================================================================
-- 00017_harden_storage_notifications_rpc.sql
-- Durcissement suite à l'audit sécurité :
--   1) Storage bucket `signatures` : la policy `signatures_read` (00003, reprise
--      telle quelle en 00004) était `USING (bucket_id = 'signatures')` ->
--      N'IMPORTE QUEL utilisateur authentifié pouvait lire TOUTES les signatures.
--   2) notifications : INSERT `WITH CHECK (true)` (00002, réaffirmé 00004) ->
--      n'importe quel authentifié pouvait injecter des notifications arbitraires
--      chez n'importe quel utilisateur (spam / phishing in-app).
--   3) RPC SECURITY DEFINER `get_managers_for_employee` (00011) et
--      `list_child_organizations` (00010) : GRANT EXECUTE TO anon -> énumération
--      de profils/organisations SANS authentification.
--
-- ⚠️ À REVOIR avant application en prod (modifie la sécurité de la base).
-- Migration idempotente (DROP IF EXISTS + CREATE, CREATE OR REPLACE, REVOKE/GRANT).
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Bucket `signatures` : restreindre la lecture aux usages réels du code.
--
-- Usages constatés :
--   a. StorageService.downloadSignature()/getSignatureUrl() (Flutter) :
--      l'utilisateur lit SA signature `{userId}/signature.png`.
--   b. StorageService.downloadSignatureForUser(userId) : prévu pour qu'un
--      manager lise la signature d'un employé -> couvert via manager_employees
--      (même modèle que pdfs_read / receipts_read de 00004).
--   c. ValidationRepositorySupabaseImpl.getValidationTimesheetData() :
--      télécharge la signature CLIENT `tokens/{validation_id}/{role}.png`
--      (écrite par l'Edge Function sign-with-token en service_role) pour
--      recomposer le PDF signé. Lecteurs légitimes = les parties de la
--      validation (employé et manager assigné) + admins.
--   d. Les Edge Functions (sign-with-token, ...) tournent en service_role et
--      BYPASSENT le RLS : pas besoin de les couvrir ici.
--
-- NB : ne JAMAIS caster (storage.foldername(name))[1] en uuid dans cette
-- policy : le dossier `tokens/` n'est pas un uuid et le cast pourrait lever
-- une erreur selon l'ordre d'évaluation. On compare toujours en ::text.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "signatures_read" ON storage.objects;
CREATE POLICY "signatures_read" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'signatures'
    AND (
      -- (a) Propriétaire : premier segment du chemin = son uid
      auth.uid()::text = (storage.foldername(name))[1]
      -- Super admin
      OR public.is_super_admin()
      -- (b) Manager lié à l'employé propriétaire (manager_employees)
      OR EXISTS (
        SELECT 1 FROM public.manager_employees me
        WHERE me.manager_id = auth.uid()
          AND me.employee_id::text = (storage.foldername(name))[1]
      )
      -- org_admin : signatures des membres de son arbre d'orgs
      OR (
        public.is_org_admin()
        AND EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id::text = (storage.foldername(name))[1]
            AND p.organization_id = ANY(public.get_my_org_ids())
        )
      )
      -- (c) Signatures par token `tokens/{validation_id}/{role}.png` :
      --     réservées aux parties de la validation + org_admin de l'org de l'employé
      OR (
        (storage.foldername(name))[1] = 'tokens'
        AND EXISTS (
          SELECT 1 FROM public.validation_requests vr
          WHERE vr.id::text = (storage.foldername(name))[2]
            AND (
              vr.employee_id = auth.uid()
              OR vr.manager_id = auth.uid()
              OR (public.is_org_admin() AND public.is_same_org(vr.employee_id))
            )
        )
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 2) notifications INSERT : remplacer WITH CHECK (true).
--
-- Écritures client constatées (via PowerSync, donc avec le JWT utilisateur —
-- le service_role des Edge Functions bypass le RLS et n'est pas concerné) :
--   a. Employé -> manager : "validation_created" à la soumission d'une demande
--      (validation_repository_supabase_impl.dart). Le lien manager_employees
--      existe au moment de cet INSERT : il est créé par le trigger
--      `link_manager_on_validation` (00015) lors de l'INSERT de la validation,
--      uploadé AVANT la notification (PowerSync préserve l'ordre des opérations).
--   b. Manager -> employé : "validation_approved" / "validation_rejected"
--      (approveValidationWithSignedPdf / rejectValidation) -> lien
--      manager_employees existant par construction.
--
-- Durcissement le plus strict qui ne casse pas ces flux : on n'autorise que
--   - s'auto-notifier,
--   - notifier son manager (lien manager_employees dans un sens),
--   - notifier son employé (lien dans l'autre sens),
--   - admins (super_admin partout, org_admin dans son arbre d'orgs).
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;
CREATE POLICY "notifications_insert" ON public.notifications
  FOR INSERT WITH CHECK (
    -- Soi-même
    user_id = auth.uid()
    -- Employé -> son manager (destinataire = manager lié)
    OR EXISTS (
      SELECT 1 FROM public.manager_employees me
      WHERE me.manager_id = notifications.user_id
        AND me.employee_id = auth.uid()
    )
    -- Manager -> son employé (destinataire = employé lié)
    OR EXISTS (
      SELECT 1 FROM public.manager_employees me
      WHERE me.manager_id = auth.uid()
        AND me.employee_id = notifications.user_id
    )
    -- Admins
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
  );

-- ---------------------------------------------------------------------------
-- 3) RPC SECURITY DEFINER : retirer l'accès anonyme.
--
-- Les seuls appels côté Flutter sont post-login (onboarding_page.dart,
-- preference_form-v2.dart, validation_repository_supabase_impl.dart), donc
-- toujours authentifiés : retirer anon ne casse rien.
-- On révoque aussi PUBLIC : CREATE FUNCTION accorde EXECUTE à PUBLIC par
-- défaut, un simple REVOKE FROM anon serait donc insuffisant.
-- ---------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.list_child_organizations() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.list_child_organizations() FROM anon;
GRANT EXECUTE ON FUNCTION public.list_child_organizations() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_child_organizations() TO service_role;

REVOKE EXECUTE ON FUNCTION public.get_managers_for_employee(UUID) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_managers_for_employee(UUID) FROM anon;
GRANT EXECUTE ON FUNCTION public.get_managers_for_employee(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_managers_for_employee(UUID) TO service_role;

-- Défense en profondeur : `get_managers_for_employee` est SECURITY DEFINER et
-- acceptait n'importe quel employee_user_id -> un authentifié pouvait énumérer
-- les managers d'une AUTRE organisation. On exige désormais que la cible soit
-- dans l'arbre d'orgs de l'appelant (is_same_org, 00006). Le client Flutter
-- n'appelle cette RPC qu'avec son propre id -> aucun impact fonctionnel.
CREATE OR REPLACE FUNCTION public.get_managers_for_employee(employee_user_id UUID)
RETURNS TABLE(id UUID, email TEXT, first_name TEXT, last_name TEXT) AS $$
  SELECT p.id, p.email, p.first_name, p.last_name
  FROM public.profiles p
  WHERE public.is_same_org(employee_user_id)
    AND p.role IN ('manager', 'admin', 'org_admin', 'super_admin')
    AND p.is_active = true
    AND p.organization_id IS NOT NULL
    AND p.organization_id = (
      SELECT ep.organization_id FROM public.profiles ep WHERE ep.id = employee_user_id
    )
  ORDER BY p.first_name, p.last_name;
$$ LANGUAGE sql SECURITY DEFINER STABLE;
