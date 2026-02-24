-- ============================================
-- TimeSheet Application - Multi-Actor Signing
-- Migration: 00007_signing_tokens
-- Adds: signing_tokens table, signing_step + client signer fields on validation_requests
-- ============================================

-- ============================================
-- 1. New table: signing_tokens
-- Stores one token per signer per validation step
-- ============================================

CREATE TABLE public.signing_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  validation_id UUID NOT NULL REFERENCES public.validation_requests(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
  signer_role TEXT NOT NULL CHECK (signer_role IN ('employee', 'manager', 'client')),
  signer_name TEXT NOT NULL,
  signer_email TEXT,
  signed_at TIMESTAMPTZ,
  signature_url TEXT,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 days'),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_signing_tokens_token ON public.signing_tokens(token);
CREATE INDEX idx_signing_tokens_validation ON public.signing_tokens(validation_id);

-- ============================================
-- 2. Add columns to validation_requests
-- ============================================

ALTER TABLE public.validation_requests
  ADD COLUMN IF NOT EXISTS client_signer_name TEXT,
  ADD COLUMN IF NOT EXISTS client_signer_email TEXT,
  ADD COLUMN IF NOT EXISTS signing_step TEXT DEFAULT 'employee'
    CHECK (signing_step IN ('employee', 'manager', 'client', 'completed'));

-- ============================================
-- 3. RLS policies for signing_tokens
-- ============================================

ALTER TABLE public.signing_tokens ENABLE ROW LEVEL SECURITY;

-- Read access: authenticated users can see tokens for their validations
-- (employees see their own, managers see their team's)
CREATE POLICY "signing_tokens_select_own" ON public.signing_tokens
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.validation_requests vr
      WHERE vr.id = signing_tokens.validation_id
        AND (vr.employee_id = auth.uid() OR vr.manager_id = auth.uid())
    )
  );

-- Anon can read by token (for the public signing page)
-- The Edge Function uses service_role, so anon access is not needed here.
-- Token validation happens in Edge Functions using service_role key.

-- Insert/Update only via service_role (Edge Functions)
-- No INSERT/UPDATE policies for anon/authenticated - all writes go through Edge Functions
