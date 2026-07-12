-- ============================================
-- Migration 00016: Allow managers to update their employees' anomalies
-- ============================================
-- Problem: the "anomalies_update" policy (00004) only allows the owner,
-- the super admin, or an org admin to UPDATE anomalies. When a manager
-- PATCHes an employee's anomaly (e.g. marking it reviewed/resolved from
-- the manager dashboard), the UPDATE matches 0 rows and fails silently.
--
-- Fix: recreate the policy with the manager conditions, same style as
-- the SELECT policies updated in 00008 (manager_employees link +
-- same-org manager), mirroring the scope of "anomalies_select".
-- ============================================

DROP POLICY IF EXISTS "anomalies_update" ON public.anomalies;
CREATE POLICY "anomalies_update" ON public.anomalies
  FOR UPDATE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR (public.is_manager() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = anomalies.user_id
    )
  );
