# Supabase Functions Deployment Guide

## Overview
This guide covers the deployment and testing of the automatic PDF regeneration system for manager signatures in validated timesheets.

## Prerequisites

1. **Supabase CLI**: Install the Supabase CLI
   ```bash
   brew install supabase/tap/supabase
   ```

2. **Project Access**: Ensure you have:
   - Supabase project URL
   - Supabase service role key
   - Access to the Supabase dashboard

3. **Environment Setup**: Link your local project to Supabase
   ```bash
   supabase link --project-ref <your-project-ref>
   ```

## Database Migration

### Step 1: Deploy the Database Changes
Deploy the migration that adds the PDF regeneration queue and triggers:

```bash
supabase db push
```

This will apply the migration from `supabase/migrations/20250201_add_pdf_regeneration_trigger.sql` which:
- Adds `pdf_with_signature` column to track regenerated PDFs
- Creates the `pdf_regeneration_queue` table
- Sets up the trigger that queues PDF regeneration on approval

### Step 2: Verify Database Changes
Connect to your database and verify:

```sql
-- Check the new column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'simple_validation_requests' 
AND column_name = 'pdf_with_signature';

-- Check the queue table exists
SELECT * FROM pdf_regeneration_queue LIMIT 1;

-- Check the trigger exists
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_name = 'queue_pdf_regeneration';
```

## Edge Functions Deployment

### Step 1: Deploy the PDF Regeneration Function
```bash
cd supabase/functions/regenerate-pdf-with-signature
supabase functions deploy regenerate-pdf-with-signature
```

### Step 2: Deploy the Queue Processor Function
```bash
cd ../process-pdf-queue
supabase functions deploy process-pdf-queue
```

### Step 3: Set Environment Variables
In the Supabase dashboard, navigate to Edge Functions settings and ensure these are set:
- `SUPABASE_URL`: Your project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Your service role key

## Setting up the Queue Processor

### Option 1: Cron Job (Recommended)
Set up a cron job in Supabase to run the queue processor every 5 minutes:

1. Go to the Supabase dashboard
2. Navigate to Database → Extensions
3. Enable the `pg_cron` extension if not already enabled
4. Create a cron job:

```sql
-- Schedule the queue processor to run every 5 minutes
SELECT cron.schedule(
  'process-pdf-queue',
  '*/5 * * * *',
  $$
  SELECT http_post(
    'https://<your-project-ref>.supabase.co/functions/v1/process-pdf-queue',
    '{}',
    'application/json',
    jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.supabase_service_role_key'),
      'Content-Type', 'application/json'
    )::text
  );
  $$
);
```

### Option 2: Manual Trigger
For testing or manual processing:

```bash
curl -X POST https://<your-project-ref>.supabase.co/functions/v1/process-pdf-queue \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{}'
```

## Storage Configuration

Ensure the `validation-pdfs` storage bucket exists and has appropriate policies:

```sql
-- Create bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('validation-pdfs', 'validation-pdfs', true)
ON CONFLICT (id) DO NOTHING;

-- Set up policies for the bucket
CREATE POLICY "Public read access" ON storage.objects
  FOR SELECT USING (bucket_id = 'validation-pdfs');

CREATE POLICY "Service role write access" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'validation-pdfs' 
    AND auth.role() = 'service_role'
  );

CREATE POLICY "Service role update access" ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'validation-pdfs' 
    AND auth.role() = 'service_role'
  );
```

## Monitoring and Logs

### View Function Logs
```bash
# View logs for the regeneration function
supabase functions logs regenerate-pdf-with-signature

# View logs for the queue processor
supabase functions logs process-pdf-queue
```

### Monitor Queue Status
```sql
-- View pending jobs
SELECT * FROM pdf_regeneration_queue 
WHERE status = 'pending' 
ORDER BY created_at;

-- View failed jobs
SELECT * FROM pdf_regeneration_queue 
WHERE status = 'failed' 
ORDER BY created_at DESC;

-- Queue statistics
SELECT 
  status, 
  COUNT(*) as count,
  MIN(created_at) as oldest,
  MAX(created_at) as newest
FROM pdf_regeneration_queue
GROUP BY status;
```

## Troubleshooting

### Common Issues

1. **PDF-lib Import Error**
   If you see errors about pdf-lib imports, ensure the import URL is correct:
   ```typescript
   import { PDFDocument, rgb, StandardFonts } from 'https://cdn.skypack.dev/pdf-lib@1.17.1'
   ```

2. **Storage Access Denied**
   Check that the service role key is being used correctly and bucket policies are set.

3. **Queue Not Processing**
   - Verify the cron job is active: `SELECT * FROM cron.job;`
   - Check function logs for errors
   - Manually trigger the processor to test

4. **Signature Not Appearing**
   - Verify the manager_signature is base64 encoded PNG
   - Check the signature positioning in the PDF (may need adjustment based on your PDF layout)
   - Review function logs for decoding errors

### Retry Failed Jobs
```sql
-- Retry all failed jobs
UPDATE pdf_regeneration_queue 
SET status = 'pending', error_message = NULL 
WHERE status = 'failed';

-- Retry specific job
UPDATE pdf_regeneration_queue 
SET status = 'pending', error_message = NULL 
WHERE id = '<job-id>';
```

## Rollback Procedure

If issues arise, you can disable the automatic regeneration:

1. **Disable the trigger**:
   ```sql
   DROP TRIGGER IF EXISTS queue_pdf_regeneration ON simple_validation_requests;
   ```

2. **Stop the cron job**:
   ```sql
   SELECT cron.unschedule('process-pdf-queue');
   ```

3. **Clear the queue**:
   ```sql
   DELETE FROM pdf_regeneration_queue WHERE status = 'pending';
   ```

## Performance Considerations

1. **Queue Processing**: The processor handles 10 jobs at a time to avoid timeouts
2. **PDF Size**: Large PDFs may take longer to process
3. **Concurrent Processing**: Consider the load on your Supabase instance

## Security Notes

- The functions use service role keys and should not be publicly accessible
- PDF integrity is maintained through the hash stored in the database
- Original PDFs are preserved; regenerated PDFs have a "_validated" suffix