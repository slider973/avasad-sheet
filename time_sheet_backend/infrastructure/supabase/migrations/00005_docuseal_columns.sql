-- Migration: Add DocuSeal columns to validation_requests
-- DocuSeal handles the electronic signature workflow with certificate of authenticity.

ALTER TABLE public.validation_requests
  ADD COLUMN IF NOT EXISTS docuseal_submission_id INTEGER,
  ADD COLUMN IF NOT EXISTS docuseal_employee_sign_url TEXT,
  ADD COLUMN IF NOT EXISTS docuseal_manager_sign_url TEXT,
  ADD COLUMN IF NOT EXISTS docuseal_status TEXT DEFAULT 'none';

-- Update status constraint to include 'signing'
ALTER TABLE public.validation_requests
  DROP CONSTRAINT IF EXISTS validation_requests_status_check;
ALTER TABLE public.validation_requests
  ADD CONSTRAINT validation_requests_status_check
    CHECK (status IN ('pending', 'signing', 'approved', 'rejected', 'expired'));
