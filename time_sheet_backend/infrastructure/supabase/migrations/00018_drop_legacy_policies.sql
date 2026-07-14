-- ============================================================================
-- 00018_drop_legacy_policies.sql
-- Purge des policies RLS HÉRITÉES présentes en prod mais absentes du repo
-- (bootstrap antérieur à 00002/00004, jamais nettoyé).
--
-- Pourquoi c'est critique : les policies RLS permissives se combinent en OR.
-- Tant que ces doublons existent, les durcissements de 00015/00017 sont
-- inopérants :
--   - val_update  : (employee_id = auth.uid() OR manager_id = auth.uid())
--                   -> l'employé peut encore modifier sa propre validation
--                      (auto-approbation), malgré 00015.
--   - val_insert  : n'impose pas status='pending', malgré 00015.
--   - profiles_select_all : USING (true) -> tout authentifié lit TOUS les
--                   profils de TOUTES les organisations.
--   - ts_*/abs_*/anom_*/exp_*/notif_*/pdf_* : owner-only, strictement inclus
--     dans les policies modernes (00004/00008/00016) -> redondants.
--
-- Seule exception : exp_delete et anom_delete étaient les SEULES policies
-- DELETE de expenses/anomalies (le jeu moderne n'en a pas), et l'app supprime
-- bien ces lignes (expense_powersync_data_source.dart, anomaly_service_powersync.dart)
-- -> on les recrée proprement, alignées sur absences_delete (00004).
--
-- Migration idempotente (DROP IF EXISTS partout).
-- ============================================================================

-- timesheet_entries (couvert par timesheet_select/insert/update/delete 00004+00008)
DROP POLICY IF EXISTS "ts_select" ON public.timesheet_entries;
DROP POLICY IF EXISTS "ts_insert" ON public.timesheet_entries;
DROP POLICY IF EXISTS "ts_update" ON public.timesheet_entries;
DROP POLICY IF EXISTS "ts_delete" ON public.timesheet_entries;

-- absences (couvert par absences_* 00004+00008)
DROP POLICY IF EXISTS "abs_select" ON public.absences;
DROP POLICY IF EXISTS "abs_insert" ON public.absences;
DROP POLICY IF EXISTS "abs_update" ON public.absences;
DROP POLICY IF EXISTS "abs_delete" ON public.absences;

-- anomalies (couvert par anomalies_* 00004+00008+00016 ; DELETE recréé plus bas)
DROP POLICY IF EXISTS "anom_select" ON public.anomalies;
DROP POLICY IF EXISTS "anom_insert" ON public.anomalies;
DROP POLICY IF EXISTS "anom_update" ON public.anomalies;
DROP POLICY IF EXISTS "anom_delete" ON public.anomalies;

-- expenses (couvert par expenses_* 00004+00008 ; DELETE recréé plus bas)
DROP POLICY IF EXISTS "exp_select" ON public.expenses;
DROP POLICY IF EXISTS "exp_insert" ON public.expenses;
DROP POLICY IF EXISTS "exp_update" ON public.expenses;
DROP POLICY IF EXISTS "exp_delete" ON public.expenses;

-- validation_requests (couvert par validations_select 00004 + validations_insert/update 00015)
DROP POLICY IF EXISTS "val_insert" ON public.validation_requests;
DROP POLICY IF EXISTS "val_select_emp" ON public.validation_requests;
DROP POLICY IF EXISTS "val_select_mgr" ON public.validation_requests;
DROP POLICY IF EXISTS "val_update" ON public.validation_requests;

-- notifications (couvert par notifications_select/update 00004 + notifications_insert 00017)
DROP POLICY IF EXISTS "notif_select" ON public.notifications;
DROP POLICY IF EXISTS "notif_insert" ON public.notifications;
DROP POLICY IF EXISTS "notif_update" ON public.notifications;

-- generated_pdfs (couvert par pdfs_select/insert 00004 + pdfs_update/delete 00009)
DROP POLICY IF EXISTS "pdf_select" ON public.generated_pdfs;
DROP POLICY IF EXISTS "pdf_insert" ON public.generated_pdfs;

-- profiles : USING (true) = fuite inter-org. Les lectures légitimes (soi-même,
-- parties d'une validation même org) passent par profiles_select (00006).
DROP POLICY IF EXISTS "profiles_select_all" ON public.profiles;

-- ---------------------------------------------------------------------------
-- DELETE manquants dans le jeu moderne (l'app supprime ses propres lignes via
-- PowerSync : re-détection d'anomalies, suppression de notes de frais).
-- Même forme que absences_delete / timesheet_delete (00004).
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "expenses_delete" ON public.expenses;
CREATE POLICY "expenses_delete" ON public.expenses
  FOR DELETE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
  );

DROP POLICY IF EXISTS "anomalies_delete" ON public.anomalies;
CREATE POLICY "anomalies_delete" ON public.anomalies
  FOR DELETE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
  );
