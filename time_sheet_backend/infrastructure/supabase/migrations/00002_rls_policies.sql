-- ============================================
-- TimeSheet Application - Row Level Security Policies
-- Migration: 00002_rls_policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timesheet_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.absences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.anomalies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.overtime_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.validation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.generated_pdfs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manager_employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

-- ============================================
-- PROFILES: see own profile + organization members
-- ============================================
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (
    id = auth.uid()
    OR organization_id IN (
      SELECT organization_id FROM public.profiles WHERE id = auth.uid()
    )
  );
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (id = auth.uid());

-- ============================================
-- TIMESHEET: employee sees own, manager sees team
-- ============================================
CREATE POLICY "timesheet_select" ON public.timesheet_entries
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = timesheet_entries.user_id
    )
  );
CREATE POLICY "timesheet_insert" ON public.timesheet_entries
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "timesheet_update" ON public.timesheet_entries
  FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "timesheet_delete" ON public.timesheet_entries
  FOR DELETE USING (user_id = auth.uid());

-- ============================================
-- ABSENCES: same logic as timesheet
-- ============================================
CREATE POLICY "absences_select" ON public.absences
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = absences.user_id
    )
  );
CREATE POLICY "absences_insert" ON public.absences
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "absences_update" ON public.absences
  FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "absences_delete" ON public.absences
  FOR DELETE USING (user_id = auth.uid());

-- ============================================
-- ANOMALIES: same logic
-- ============================================
CREATE POLICY "anomalies_select" ON public.anomalies
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = anomalies.user_id
    )
  );
CREATE POLICY "anomalies_insert" ON public.anomalies
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "anomalies_update" ON public.anomalies
  FOR UPDATE USING (user_id = auth.uid());

-- ============================================
-- EXPENSES: employee sees own, manager approves
-- ============================================
CREATE POLICY "expenses_select" ON public.expenses
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = expenses.user_id
    )
  );
CREATE POLICY "expenses_insert" ON public.expenses
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "expenses_update_own" ON public.expenses
  FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "expenses_update_manager" ON public.expenses
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = expenses.user_id
    )
  );

-- ============================================
-- VALIDATIONS: employee and manager can see
-- ============================================
CREATE POLICY "validations_select" ON public.validation_requests
  FOR SELECT USING (
    employee_id = auth.uid() OR manager_id = auth.uid()
  );
CREATE POLICY "validations_insert" ON public.validation_requests
  FOR INSERT WITH CHECK (employee_id = auth.uid());
CREATE POLICY "validations_update" ON public.validation_requests
  FOR UPDATE USING (
    employee_id = auth.uid() OR manager_id = auth.uid()
  );

-- ============================================
-- NOTIFICATIONS: own only
-- ============================================
CREATE POLICY "notifications_select" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "notifications_update" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "notifications_insert" ON public.notifications
  FOR INSERT WITH CHECK (true);

-- ============================================
-- GENERATED PDFS: own + manager
-- ============================================
CREATE POLICY "pdfs_select" ON public.generated_pdfs
  FOR SELECT USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = generated_pdfs.user_id
    )
  );
CREATE POLICY "pdfs_insert" ON public.generated_pdfs
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- ============================================
-- MANAGER-EMPLOYEES: manager and admin manage
-- ============================================
CREATE POLICY "manager_employees_select" ON public.manager_employees
  FOR SELECT USING (
    manager_id = auth.uid() OR employee_id = auth.uid()
  );
CREATE POLICY "manager_employees_manage" ON public.manager_employees
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('manager', 'admin')
    )
  );

-- ============================================
-- ORGANIZATIONS: members see their org
-- ============================================
CREATE POLICY "orgs_select" ON public.organizations
  FOR SELECT USING (
    id IN (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
  );

-- ============================================
-- OVERTIME CONFIG: own only
-- ============================================
CREATE POLICY "overtime_select" ON public.overtime_configurations
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "overtime_insert" ON public.overtime_configurations
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "overtime_update" ON public.overtime_configurations
  FOR UPDATE USING (user_id = auth.uid());
