-- ============================================
-- TimeSheet Application - Storage UPDATE/DELETE policies
-- Migration: 00012_storage_update_delete_policies
-- Fixes: StorageException "new row violates row-level security policy"
-- when uploading files with upsert: true (file already exists)
-- ============================================

-- PDFs bucket - UPDATE (needed for upsert: true when file already exists)
CREATE POLICY "pdfs_update" ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'pdfs'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- PDFs bucket - DELETE
CREATE POLICY "pdfs_delete" ON storage.objects FOR DELETE
  USING (
    bucket_id = 'pdfs'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Signatures bucket - UPDATE
CREATE POLICY "signatures_update" ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'signatures'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Signatures bucket - DELETE
CREATE POLICY "signatures_delete" ON storage.objects FOR DELETE
  USING (
    bucket_id = 'signatures'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Receipts bucket - UPDATE
CREATE POLICY "receipts_update" ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'receipts'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Receipts bucket - DELETE
CREATE POLICY "receipts_delete" ON storage.objects FOR DELETE
  USING (
    bucket_id = 'receipts'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
