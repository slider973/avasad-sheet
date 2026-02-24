-- ============================================
-- Migration 00008: Allow same-org managers to read employee data
-- ============================================
-- Problem: useTeamMembers() shows all org members in the dropdown,
-- but RLS only allows reading timesheet/absences/anomalies/expenses
-- via explicit manager_employees links. This causes empty data
-- for managers viewing employees in the same org without explicit links.
--
-- Fix: Add "manager + same org" condition to SELECT policies.
-- ============================================

-- Helper function: is_manager()
CREATE OR REPLACE FUNCTION public.is_manager() RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'manager'
  )
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================
-- TIMESHEET_ENTRIES: update SELECT policy
-- ============================================
DROP POLICY IF EXISTS "timesheet_select" ON public.timesheet_entries;
CREATE POLICY "timesheet_select" ON public.timesheet_entries
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR (public.is_manager() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = timesheet_entries.user_id
    )
  );

-- ============================================
-- ABSENCES: update SELECT policy
-- ============================================
DROP POLICY IF EXISTS "absences_select" ON public.absences;
CREATE POLICY "absences_select" ON public.absences
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR (public.is_manager() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = absences.user_id
    )
  );

-- ============================================
-- ANOMALIES: update SELECT policy
-- ============================================
DROP POLICY IF EXISTS "anomalies_select" ON public.anomalies;
CREATE POLICY "anomalies_select" ON public.anomalies
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR (public.is_manager() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = anomalies.user_id
    )
  );

-- ============================================
-- EXPENSES: update SELECT policy
-- ============================================
DROP POLICY IF EXISTS "expenses_select" ON public.expenses;
CREATE POLICY "expenses_select" ON public.expenses
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR (public.is_manager() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = expenses.user_id
    )
  );
