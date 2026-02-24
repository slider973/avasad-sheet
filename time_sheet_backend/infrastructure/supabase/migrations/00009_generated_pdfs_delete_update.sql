-- ============================================
-- Migration 00009: Add DELETE and UPDATE policies for generated_pdfs
-- ============================================
-- Problem: RLS is enabled on generated_pdfs but only SELECT and INSERT
-- policies exist. Without a DELETE policy, Supabase silently blocks
-- delete operations, causing PowerSync to re-sync deleted rows.
-- ============================================

-- DELETE: users can delete their own PDFs
CREATE POLICY "pdfs_delete" ON public.generated_pdfs
  FOR DELETE USING (user_id = auth.uid());

-- UPDATE: users can update their own PDFs
CREATE POLICY "pdfs_update" ON public.generated_pdfs
  FOR UPDATE USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
