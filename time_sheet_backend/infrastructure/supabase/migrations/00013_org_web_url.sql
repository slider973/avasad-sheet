-- 00013_org_web_url.sql
-- Add web_url column to organizations for multi-tenant URL resolution.
-- Each organization can have its own web domain (e.g. https://timesheet.staticflow.ch).
-- Edge Functions use this to generate correct signing URLs per organization.

ALTER TABLE public.organizations
  ADD COLUMN IF NOT EXISTS web_url TEXT;

COMMENT ON COLUMN public.organizations.web_url
  IS 'Base URL of the organization web app (e.g. https://timesheet.staticflow.ch)';

-- Helper RPC: resolve the web URL for a given validation request.
-- Joins validation_requests -> profiles -> organizations to get the org web_url.
-- Returns NULL if the org has no web_url set (caller falls back to WEB_URL env var).
CREATE OR REPLACE FUNCTION public.get_org_web_url(p_validation_id UUID)
RETURNS TEXT AS $$
  SELECT o.web_url
  FROM validation_requests vr
  JOIN profiles p ON p.id = vr.employee_id
  JOIN organizations o ON o.id = p.organization_id
  WHERE vr.id = p_validation_id
$$ LANGUAGE sql SECURITY DEFINER STABLE;
