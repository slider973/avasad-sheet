-- ============================================
-- TimeSheet Application - Multi-Tenant Roles & RLS
-- Migration: 00004_multi_tenant_roles
-- Adds: super_admin, org_admin roles
-- Updates: All RLS policies for org isolation
-- ============================================

-- ============================================
-- 1. SCHEMA CHANGES
-- ============================================

-- Expand role constraint to include super_admin and org_admin
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('employee', 'manager', 'admin', 'org_admin', 'super_admin'));

-- Enrich organizations table
ALTER TABLE public.organizations ADD COLUMN IF NOT EXISTS slug TEXT UNIQUE;
ALTER TABLE public.organizations ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE public.organizations ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- Trigger for organizations updated_at
CREATE TRIGGER tr_organizations_updated BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- 2. HELPER FUNCTIONS FOR RLS
-- ============================================

CREATE OR REPLACE FUNCTION public.get_my_role() RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.get_my_org_id() RETURNS UUID AS $$
  SELECT organization_id FROM public.profiles WHERE id = auth.uid()
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_super_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'super_admin')
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_org_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'org_admin')
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_same_org(target_user_id UUID) RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = target_user_id AND organization_id = public.get_my_org_id()
  )
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================
-- 3. DROP ALL EXISTING RLS POLICIES
-- ============================================

-- profiles
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;

-- timesheet_entries
DROP POLICY IF EXISTS "timesheet_select" ON public.timesheet_entries;
DROP POLICY IF EXISTS "timesheet_insert" ON public.timesheet_entries;
DROP POLICY IF EXISTS "timesheet_update" ON public.timesheet_entries;
DROP POLICY IF EXISTS "timesheet_delete" ON public.timesheet_entries;

-- absences
DROP POLICY IF EXISTS "absences_select" ON public.absences;
DROP POLICY IF EXISTS "absences_insert" ON public.absences;
DROP POLICY IF EXISTS "absences_update" ON public.absences;
DROP POLICY IF EXISTS "absences_delete" ON public.absences;

-- anomalies
DROP POLICY IF EXISTS "anomalies_select" ON public.anomalies;
DROP POLICY IF EXISTS "anomalies_insert" ON public.anomalies;
DROP POLICY IF EXISTS "anomalies_update" ON public.anomalies;

-- expenses
DROP POLICY IF EXISTS "expenses_select" ON public.expenses;
DROP POLICY IF EXISTS "expenses_insert" ON public.expenses;
DROP POLICY IF EXISTS "expenses_update_own" ON public.expenses;
DROP POLICY IF EXISTS "expenses_update_manager" ON public.expenses;

-- validation_requests
DROP POLICY IF EXISTS "validations_select" ON public.validation_requests;
DROP POLICY IF EXISTS "validations_insert" ON public.validation_requests;
DROP POLICY IF EXISTS "validations_update" ON public.validation_requests;

-- notifications
DROP POLICY IF EXISTS "notifications_select" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert" ON public.notifications;

-- generated_pdfs
DROP POLICY IF EXISTS "pdfs_select" ON public.generated_pdfs;
DROP POLICY IF EXISTS "pdfs_insert" ON public.generated_pdfs;

-- manager_employees
DROP POLICY IF EXISTS "manager_employees_select" ON public.manager_employees;
DROP POLICY IF EXISTS "manager_employees_manage" ON public.manager_employees;

-- organizations
DROP POLICY IF EXISTS "orgs_select" ON public.organizations;

-- overtime_configurations
DROP POLICY IF EXISTS "overtime_select" ON public.overtime_configurations;
DROP POLICY IF EXISTS "overtime_insert" ON public.overtime_configurations;
DROP POLICY IF EXISTS "overtime_update" ON public.overtime_configurations;

-- storage policies
DROP POLICY IF EXISTS "pdfs_upload" ON storage.objects;
DROP POLICY IF EXISTS "pdfs_read" ON storage.objects;
DROP POLICY IF EXISTS "signatures_upload" ON storage.objects;
DROP POLICY IF EXISTS "signatures_read" ON storage.objects;
DROP POLICY IF EXISTS "receipts_upload" ON storage.objects;
DROP POLICY IF EXISTS "receipts_read" ON storage.objects;

-- ============================================
-- 4. NEW RLS POLICIES - ORGANIZATIONS
-- ============================================

-- SELECT: own org members + super_admin sees all
CREATE POLICY "orgs_select" ON public.organizations
  FOR SELECT USING (
    public.is_super_admin()
    OR id = public.get_my_org_id()
  );

-- INSERT: super_admin only
CREATE POLICY "orgs_insert" ON public.organizations
  FOR INSERT WITH CHECK (
    public.is_super_admin()
  );

-- UPDATE: super_admin or org_admin of this org
CREATE POLICY "orgs_update" ON public.organizations
  FOR UPDATE USING (
    public.is_super_admin()
    OR (public.is_org_admin() AND id = public.get_my_org_id())
  );

-- DELETE: super_admin only
CREATE POLICY "orgs_delete" ON public.organizations
  FOR DELETE USING (
    public.is_super_admin()
  );

-- ============================================
-- 5. NEW RLS POLICIES - PROFILES
-- ============================================

-- SELECT: own + same org + super_admin sees all
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (
    public.is_super_admin()
    OR id = auth.uid()
    OR organization_id = public.get_my_org_id()
  );

-- UPDATE: own profile, org_admin can update same org, super_admin can update all
CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE USING (
    id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND organization_id = public.get_my_org_id())
  );

-- INSERT: super_admin only (normal signup goes through trigger)
CREATE POLICY "profiles_insert" ON public.profiles
  FOR INSERT WITH CHECK (
    id = auth.uid()
    OR public.is_super_admin()
  );

-- ============================================
-- 6. NEW RLS POLICIES - TIMESHEET_ENTRIES
-- ============================================

-- SELECT: own + manager team + org_admin same org + super_admin
CREATE POLICY "timesheet_select" ON public.timesheet_entries
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = timesheet_entries.user_id
    )
  );

CREATE POLICY "timesheet_insert" ON public.timesheet_entries
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "timesheet_update" ON public.timesheet_entries
  FOR UPDATE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
  );

CREATE POLICY "timesheet_delete" ON public.timesheet_entries
  FOR DELETE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
  );

-- ============================================
-- 7. NEW RLS POLICIES - ABSENCES
-- ============================================

CREATE POLICY "absences_select" ON public.absences
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = absences.user_id
    )
  );

CREATE POLICY "absences_insert" ON public.absences
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "absences_update" ON public.absences
  FOR UPDATE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
  );

CREATE POLICY "absences_delete" ON public.absences
  FOR DELETE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
  );

-- ============================================
-- 8. NEW RLS POLICIES - ANOMALIES
-- ============================================

CREATE POLICY "anomalies_select" ON public.anomalies
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = anomalies.user_id
    )
  );

CREATE POLICY "anomalies_insert" ON public.anomalies
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "anomalies_update" ON public.anomalies
  FOR UPDATE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
  );

-- ============================================
-- 9. NEW RLS POLICIES - EXPENSES
-- ============================================

CREATE POLICY "expenses_select" ON public.expenses
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = expenses.user_id
    )
  );

CREATE POLICY "expenses_insert" ON public.expenses
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "expenses_update" ON public.expenses
  FOR UPDATE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = expenses.user_id
    )
  );

-- ============================================
-- 10. NEW RLS POLICIES - OVERTIME_CONFIGURATIONS
-- ============================================

CREATE POLICY "overtime_select" ON public.overtime_configurations
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = overtime_configurations.user_id
    )
  );

CREATE POLICY "overtime_insert" ON public.overtime_configurations
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
  );

CREATE POLICY "overtime_update" ON public.overtime_configurations
  FOR UPDATE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
  );

-- ============================================
-- 11. NEW RLS POLICIES - VALIDATION_REQUESTS
-- ============================================

CREATE POLICY "validations_select" ON public.validation_requests
  FOR SELECT USING (
    employee_id = auth.uid()
    OR manager_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(employee_id))
  );

CREATE POLICY "validations_insert" ON public.validation_requests
  FOR INSERT WITH CHECK (employee_id = auth.uid());

CREATE POLICY "validations_update" ON public.validation_requests
  FOR UPDATE USING (
    employee_id = auth.uid()
    OR manager_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(employee_id))
  );

-- ============================================
-- 12. NEW RLS POLICIES - NOTIFICATIONS
-- ============================================

CREATE POLICY "notifications_select" ON public.notifications
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
  );

CREATE POLICY "notifications_insert" ON public.notifications
  FOR INSERT WITH CHECK (true);

CREATE POLICY "notifications_update" ON public.notifications
  FOR UPDATE USING (
    user_id = auth.uid()
    OR public.is_super_admin()
  );

-- ============================================
-- 13. NEW RLS POLICIES - GENERATED_PDFS
-- ============================================

CREATE POLICY "pdfs_select" ON public.generated_pdfs
  FOR SELECT USING (
    user_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(user_id))
    OR EXISTS (
      SELECT 1 FROM public.manager_employees
      WHERE manager_id = auth.uid() AND employee_id = generated_pdfs.user_id
    )
  );

CREATE POLICY "pdfs_insert" ON public.generated_pdfs
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- ============================================
-- 14. NEW RLS POLICIES - MANAGER_EMPLOYEES
-- ============================================

CREATE POLICY "manager_employees_select" ON public.manager_employees
  FOR SELECT USING (
    manager_id = auth.uid()
    OR employee_id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND (
      public.is_same_org(manager_id) OR public.is_same_org(employee_id)
    ))
  );

CREATE POLICY "manager_employees_insert" ON public.manager_employees
  FOR INSERT WITH CHECK (
    public.is_super_admin()
    OR (public.is_org_admin() AND public.is_same_org(manager_id) AND public.is_same_org(employee_id))
    OR (public.get_my_role() IN ('manager', 'admin') AND manager_id = auth.uid())
  );

CREATE POLICY "manager_employees_update" ON public.manager_employees
  FOR UPDATE USING (
    public.is_super_admin()
    OR (public.is_org_admin() AND (
      public.is_same_org(manager_id) OR public.is_same_org(employee_id)
    ))
  );

CREATE POLICY "manager_employees_delete" ON public.manager_employees
  FOR DELETE USING (
    public.is_super_admin()
    OR (public.is_org_admin() AND (
      public.is_same_org(manager_id) OR public.is_same_org(employee_id)
    ))
    OR (public.get_my_role() IN ('manager', 'admin') AND manager_id = auth.uid())
  );

-- ============================================
-- 15. NEW STORAGE POLICIES
-- ============================================

-- PDFs bucket
CREATE POLICY "pdfs_upload" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'pdfs'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "pdfs_read" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'pdfs'
    AND (
      auth.uid()::text = (storage.foldername(name))[1]
      OR public.is_super_admin()
      OR (public.is_org_admin() AND public.is_same_org((storage.foldername(name))[1]::uuid))
      OR EXISTS (
        SELECT 1 FROM public.manager_employees
        WHERE manager_id = auth.uid()
        AND employee_id::text = (storage.foldername(name))[1]
      )
    )
  );

-- Signatures bucket
CREATE POLICY "signatures_upload" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'signatures'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "signatures_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'signatures');

-- Receipts bucket
CREATE POLICY "receipts_upload" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'receipts'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "receipts_read" ON storage.objects FOR SELECT
  USING (
    bucket_id = 'receipts'
    AND (
      auth.uid()::text = (storage.foldername(name))[1]
      OR public.is_super_admin()
      OR (public.is_org_admin() AND public.is_same_org((storage.foldername(name))[1]::uuid))
      OR EXISTS (
        SELECT 1 FROM public.manager_employees
        WHERE manager_id = auth.uid()
        AND employee_id::text = (storage.foldername(name))[1]
      )
    )
  );

-- ============================================
-- 16. PERFORMANCE INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS idx_profiles_org_id ON public.profiles(organization_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- ============================================
-- 17. SEED SUPER_ADMIN
-- ============================================

UPDATE public.profiles SET role = 'super_admin' WHERE email = 'lemaine.jonathan@gmail.com';
