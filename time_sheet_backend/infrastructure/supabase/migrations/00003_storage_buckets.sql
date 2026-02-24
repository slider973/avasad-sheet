-- ============================================
-- TimeSheet Application - Storage Buckets & Policies
-- Migration: 00003_storage_buckets
-- ============================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES ('pdfs', 'pdfs', false);
INSERT INTO storage.buckets (id, name, public) VALUES ('signatures', 'signatures', false);
INSERT INTO storage.buckets (id, name, public) VALUES ('receipts', 'receipts', false);

-- ============================================
-- PDFs bucket policies
-- ============================================
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
      OR EXISTS (
        SELECT 1 FROM public.manager_employees
        WHERE manager_id = auth.uid()
        AND employee_id::text = (storage.foldername(name))[1]
      )
    )
  );

-- ============================================
-- Signatures bucket policies
-- ============================================
CREATE POLICY "signatures_upload" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'signatures'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "signatures_read" ON storage.objects FOR SELECT
  USING (bucket_id = 'signatures');

-- ============================================
-- Receipts bucket policies (expense attachments)
-- ============================================
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
      OR EXISTS (
        SELECT 1 FROM public.manager_employees
        WHERE manager_id = auth.uid()
        AND employee_id::text = (storage.foldername(name))[1]
      )
    )
  );
