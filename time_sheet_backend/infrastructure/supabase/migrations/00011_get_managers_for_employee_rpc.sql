-- ============================================
-- TimeSheet Application - Get managers for employee RPC
-- Migration: 00011_get_managers_for_employee_rpc
-- Adds: RPC function to get managers in the same organization
-- ============================================

-- Returns managers (role = manager/admin/org_admin/super_admin) in the same
-- organization as the given employee only.
-- Uses SECURITY DEFINER to bypass RLS so employees can always see their managers.
CREATE OR REPLACE FUNCTION public.get_managers_for_employee(employee_user_id UUID)
RETURNS TABLE(id UUID, email TEXT, first_name TEXT, last_name TEXT) AS $$
  SELECT p.id, p.email, p.first_name, p.last_name
  FROM public.profiles p
  WHERE p.role IN ('manager', 'admin', 'org_admin', 'super_admin')
    AND p.is_active = true
    AND p.organization_id IS NOT NULL
    AND p.organization_id = (
      SELECT ep.organization_id FROM public.profiles ep WHERE ep.id = employee_user_id
    )
  ORDER BY p.first_name, p.last_name;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_managers_for_employee(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_managers_for_employee(UUID) TO anon;
