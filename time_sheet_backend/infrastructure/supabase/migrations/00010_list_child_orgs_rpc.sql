-- ============================================
-- TimeSheet Application - List child organizations RPC
-- Migration: 00010_list_child_orgs_rpc
-- Adds: RPC function to list child organizations for onboarding
-- ============================================

-- Returns all child organizations (parent_id IS NOT NULL) that are active.
-- Uses SECURITY DEFINER to bypass RLS so new users during onboarding
-- can see the list of organizations to join.
CREATE OR REPLACE FUNCTION public.list_child_organizations()
RETURNS TABLE(id UUID, name TEXT) AS $$
  SELECT o.id, o.name
  FROM public.organizations o
  WHERE o.parent_id IS NOT NULL
    AND o.is_active = true
  ORDER BY o.name;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.list_child_organizations() TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_child_organizations() TO anon;
