-- ============================================
-- TimeSheet Application - Organization Hierarchy
-- Migration: 00006_org_hierarchy
-- Adds: parent_id on organizations (1-level deep)
-- Updates: get_my_org_ids(), is_same_org(), org/profile policies
-- ============================================

-- ============================================
-- 1. SCHEMA: Add parent_id to organizations
-- ============================================

ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.organizations(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_organizations_parent_id ON public.organizations(parent_id);

-- ============================================
-- 2. CONSTRAINT: Max 1 level of hierarchy depth
-- ============================================

CREATE OR REPLACE FUNCTION public.check_org_hierarchy_depth()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.parent_id IS NOT NULL THEN
    -- The parent must be a root org (parent_id IS NULL)
    IF EXISTS (SELECT 1 FROM public.organizations WHERE id = NEW.parent_id AND parent_id IS NOT NULL) THEN
      RAISE EXCEPTION 'Hierarchie limitee a un niveau. Le parent doit etre une org racine.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_check_org_hierarchy
  BEFORE INSERT OR UPDATE OF parent_id ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION public.check_org_hierarchy_depth();

-- ============================================
-- 3. HELPER: get_my_org_ids()
-- Returns all org IDs accessible by the caller:
-- - org_admin: own org + all child orgs
-- - others: just own org
-- ============================================

CREATE OR REPLACE FUNCTION public.get_my_org_ids() RETURNS UUID[] AS $$
  SELECT CASE
    WHEN (SELECT role FROM public.profiles WHERE id = auth.uid()) IN ('org_admin', 'super_admin') THEN
      ARRAY(
        SELECT id FROM public.organizations
        WHERE id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
           OR parent_id = (SELECT organization_id FROM public.profiles WHERE id = auth.uid())
      )
    ELSE
      ARRAY[(SELECT organization_id FROM public.profiles WHERE id = auth.uid())]
  END
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================
-- 4. UPDATE: is_same_org() - propagates to ALL existing policies
-- ============================================

CREATE OR REPLACE FUNCTION public.is_same_org(target_user_id UUID) RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = target_user_id
      AND organization_id = ANY(public.get_my_org_ids())
  )
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ============================================
-- 5. UPDATE: Organizations policies (the only ones to rewrite)
-- ============================================

-- DROP existing
DROP POLICY IF EXISTS "orgs_select" ON public.organizations;
DROP POLICY IF EXISTS "orgs_insert" ON public.organizations;
DROP POLICY IF EXISTS "orgs_update" ON public.organizations;
-- Keep orgs_delete as-is (super_admin only)

-- SELECT: org_admin sees own org + child orgs
CREATE POLICY "orgs_select" ON public.organizations
  FOR SELECT USING (
    public.is_super_admin()
    OR id = ANY(public.get_my_org_ids())
  );

-- INSERT: super_admin can create any org, org_admin can create children under their org
CREATE POLICY "orgs_insert" ON public.organizations
  FOR INSERT WITH CHECK (
    public.is_super_admin()
    OR (public.is_org_admin() AND parent_id = public.get_my_org_id())
  );

-- UPDATE: super_admin all, org_admin can update their org tree
CREATE POLICY "orgs_update" ON public.organizations
  FOR UPDATE USING (
    public.is_super_admin()
    OR (public.is_org_admin() AND id = ANY(public.get_my_org_ids()))
  );

-- ============================================
-- 6. UPDATE: Profiles policies
-- ============================================

DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;

-- SELECT: own + all orgs in hierarchy + super_admin
CREATE POLICY "profiles_select" ON public.profiles
  FOR SELECT USING (
    public.is_super_admin()
    OR id = auth.uid()
    OR organization_id = ANY(public.get_my_org_ids())
  );

-- UPDATE: own, super_admin, org_admin for their org tree
CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE USING (
    id = auth.uid()
    OR public.is_super_admin()
    OR (public.is_org_admin() AND organization_id = ANY(public.get_my_org_ids()))
  );
