# PDF Regeneration Monitoring & Error Management

## Monitoring Dashboard Queries

### Real-time Queue Status
```sql
-- Create a view for easy monitoring
CREATE OR REPLACE VIEW v_pdf_queue_status AS
SELECT 
  status,
  COUNT(*) as count,
  MIN(created_at) as oldest_job,
  MAX(created_at) as newest_job,
  AVG(EXTRACT(EPOCH FROM (processed_at - created_at))) as avg_processing_seconds
FROM pdf_regeneration_queue
GROUP BY status;

-- Query the view
SELECT * FROM v_pdf_queue_status;
```

### Job Processing Metrics
```sql
-- Hourly processing statistics
SELECT 
  DATE_TRUNC('hour', created_at) as hour,
  COUNT(*) as total_jobs,
  SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
  SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
  ROUND(100.0 * SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate
FROM pdf_regeneration_queue
WHERE created_at > NOW() - INTERVAL '24 hours'
GROUP BY hour
ORDER BY hour DESC;
```

### Failed Jobs Analysis
```sql
-- Analyze failure patterns
SELECT 
  error_message,
  COUNT(*) as occurrences,
  MIN(created_at) as first_seen,
  MAX(created_at) as last_seen
FROM pdf_regeneration_queue
WHERE status = 'failed'
GROUP BY error_message
ORDER BY occurrences DESC;
```

## Alert Queries

### Critical Alerts

1. **Queue Backlog Alert**
```sql
-- Alert if more than 50 jobs pending for over 30 minutes
SELECT COUNT(*) as backlog_count
FROM pdf_regeneration_queue
WHERE status = 'pending'
AND created_at < NOW() - INTERVAL '30 minutes';
```

2. **High Failure Rate Alert**
```sql
-- Alert if failure rate > 10% in last hour
SELECT 
  ROUND(100.0 * SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 2) as failure_rate
FROM pdf_regeneration_queue
WHERE created_at > NOW() - INTERVAL '1 hour';
```

3. **Stuck Jobs Alert**
```sql
-- Alert for jobs processing for over 5 minutes
SELECT 
  id,
  validation_id,
  created_at,
  EXTRACT(EPOCH FROM (NOW() - created_at)) / 60 as minutes_processing
FROM pdf_regeneration_queue
WHERE status = 'processing'
AND created_at < NOW() - INTERVAL '5 minutes';
```

## Error Handling Procedures

### Common Error Patterns

#### 1. Storage Errors
**Error**: "Failed to download PDF" or "Failed to upload modified PDF"

**Detection**:
```sql
SELECT * FROM pdf_regeneration_queue
WHERE status = 'failed'
AND error_message LIKE '%Failed to%load%PDF%'
ORDER BY created_at DESC;
```

**Resolution**:
```sql
-- Check storage bucket status
SELECT 
  bucket_id,
  COUNT(*) as object_count,
  SUM(metadata->>'size')::BIGINT / 1024 / 1024 as total_mb
FROM storage.objects
WHERE bucket_id = 'validation-pdfs'
GROUP BY bucket_id;

-- Retry affected jobs
UPDATE pdf_regeneration_queue
SET status = 'pending', error_message = NULL
WHERE status = 'failed'
AND error_message LIKE '%Failed to%load%PDF%';
```

#### 2. Signature Decoding Errors
**Error**: "Invalid signature format" or base64 decoding failures

**Detection**:
```sql
-- Find validations with potentially corrupt signatures
SELECT 
  v.id,
  v.employee_id,
  LENGTH(v.manager_signature) as signature_length,
  LEFT(v.manager_signature, 50) as signature_preview
FROM simple_validation_requests v
JOIN pdf_regeneration_queue q ON q.validation_id = v.id
WHERE q.status = 'failed'
AND q.error_message LIKE '%signature%';
```

**Resolution**:
```sql
-- Mark for manual review
UPDATE pdf_regeneration_queue
SET error_message = CONCAT(error_message, ' - NEEDS MANUAL REVIEW')
WHERE status = 'failed'
AND error_message LIKE '%signature%';
```

#### 3. PDF Processing Timeouts
**Error**: Function execution timeout

**Detection**:
```sql
-- Identify large PDFs that might timeout
SELECT 
  v.id,
  v.pdf_path,
  v.pdf_size_bytes / 1024 / 1024 as pdf_mb,
  q.error_message
FROM simple_validation_requests v
JOIN pdf_regeneration_queue q ON q.validation_id = v.id
WHERE q.status = 'failed'
AND v.pdf_size_bytes > 10 * 1024 * 1024; -- PDFs larger than 10MB
```

**Resolution**:
- Increase function timeout in Supabase dashboard
- Process large PDFs separately
- Implement PDF optimization

### Automated Recovery Scripts

#### 1. Auto-Retry Failed Jobs
```sql
-- Function to automatically retry failed jobs
CREATE OR REPLACE FUNCTION retry_failed_pdf_jobs(
  max_retries INTEGER DEFAULT 3,
  older_than INTERVAL DEFAULT '5 minutes'
)
RETURNS TABLE(retried_count INTEGER) AS $$
DECLARE
  retry_count INTEGER;
BEGIN
  -- Count retries per job (stored in error_message for simplicity)
  WITH jobs_to_retry AS (
    SELECT id
    FROM pdf_regeneration_queue
    WHERE status = 'failed'
    AND created_at < NOW() - older_than
    AND (
      error_message NOT LIKE '%RETRY:%' 
      OR CAST(SUBSTRING(error_message FROM 'RETRY:(\d+)') AS INTEGER) < max_retries
    )
    LIMIT 20 -- Process in batches
  )
  UPDATE pdf_regeneration_queue
  SET 
    status = 'pending',
    error_message = CASE 
      WHEN error_message LIKE '%RETRY:%' THEN
        REGEXP_REPLACE(error_message, 'RETRY:\d+', 'RETRY:' || 
          (CAST(SUBSTRING(error_message FROM 'RETRY:(\d+)') AS INTEGER) + 1)::TEXT)
      ELSE
        CONCAT(error_message, ' RETRY:1')
    END
  WHERE id IN (SELECT id FROM jobs_to_retry);
  
  GET DIAGNOSTICS retry_count = ROW_COUNT;
  RETURN QUERY SELECT retry_count;
END;
$$ LANGUAGE plpgsql;

-- Schedule automatic retries every 15 minutes
SELECT cron.schedule(
  'retry-failed-pdf-jobs',
  '*/15 * * * *',
  'SELECT retry_failed_pdf_jobs();'
);
```

#### 2. Clean Up Old Queue Entries
```sql
-- Function to archive old completed/failed jobs
CREATE OR REPLACE FUNCTION archive_old_pdf_jobs(
  older_than INTERVAL DEFAULT '7 days'
)
RETURNS TABLE(archived_count INTEGER) AS $$
DECLARE
  archive_count INTEGER;
BEGIN
  -- Move to archive table (create if needed)
  CREATE TABLE IF NOT EXISTS pdf_regeneration_queue_archive (
    LIKE pdf_regeneration_queue INCLUDING ALL
  );
  
  WITH jobs_to_archive AS (
    DELETE FROM pdf_regeneration_queue
    WHERE status IN ('completed', 'failed')
    AND processed_at < NOW() - older_than
    RETURNING *
  )
  INSERT INTO pdf_regeneration_queue_archive
  SELECT * FROM jobs_to_archive;
  
  GET DIAGNOSTICS archive_count = ROW_COUNT;
  RETURN QUERY SELECT archive_count;
END;
$$ LANGUAGE plpgsql;

-- Schedule daily cleanup
SELECT cron.schedule(
  'archive-old-pdf-jobs',
  '0 2 * * *', -- 2 AM daily
  'SELECT archive_old_pdf_jobs();'
);
```

## Monitoring Integration

### Supabase Logs Integration
```javascript
// Add to your Edge Functions for structured logging
const log = (level, message, metadata = {}) => {
  console.log(JSON.stringify({
    timestamp: new Date().toISOString(),
    level,
    message,
    ...metadata
  }));
};

// Usage in functions
log('info', 'Processing validation', { validationId, step: 'download' });
log('error', 'PDF regeneration failed', { validationId, error: error.message });
```

### Health Check Endpoint
Create a health check function:

```typescript
// supabase/functions/pdf-health-check/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  )

  try {
    // Check queue status
    const { data: queueStatus, error: queueError } = await supabaseClient
      .from('v_pdf_queue_status')
      .select('*')

    // Check storage accessibility
    const { data: storageTest, error: storageError } = await supabaseClient
      .storage
      .from('validation-pdfs')
      .list('', { limit: 1 })

    // Check for stuck jobs
    const { data: stuckJobs, error: stuckError } = await supabaseClient
      .from('pdf_regeneration_queue')
      .select('count')
      .eq('status', 'processing')
      .lt('created_at', new Date(Date.now() - 5 * 60 * 1000).toISOString())

    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      checks: {
        queue: queueError ? 'error' : 'ok',
        storage: storageError ? 'error' : 'ok',
        stuckJobs: stuckJobs?.[0]?.count > 0 ? 'warning' : 'ok'
      },
      metrics: {
        queueStatus,
        stuckJobCount: stuckJobs?.[0]?.count || 0
      }
    }

    // Determine overall health
    if (Object.values(health.checks).includes('error')) {
      health.status = 'unhealthy'
    } else if (Object.values(health.checks).includes('warning')) {
      health.status = 'degraded'
    }

    return new Response(JSON.stringify(health), {
      headers: { 'Content-Type': 'application/json' },
      status: health.status === 'healthy' ? 200 : 503
    })
  } catch (error) {
    return new Response(JSON.stringify({
      status: 'unhealthy',
      error: error.message
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 503
    })
  }
})
```

### External Monitoring
Set up external monitoring with tools like:

1. **UptimeRobot**: Monitor the health check endpoint
2. **Datadog/New Relic**: Send custom metrics
3. **PagerDuty**: Alert on critical failures

Example cURL for monitoring:
```bash
# Health check
curl -s https://<project-ref>.supabase.co/functions/v1/pdf-health-check | jq .

# Queue status check
curl -s -X POST https://<project-ref>.supabase.co/rest/v1/rpc/get_queue_metrics \
  -H "apikey: <anon-key>" \
  -H "Content-Type: application/json" \
  -d '{}' | jq .
```

## Debugging Guide

### Enable Verbose Logging
```sql
-- Add debug column to queue table
ALTER TABLE pdf_regeneration_queue 
ADD COLUMN IF NOT EXISTS debug_log JSONB DEFAULT '{}';

-- Update functions to log debug info
UPDATE pdf_regeneration_queue
SET debug_log = jsonb_build_object(
  'start_time', NOW(),
  'pdf_size', (SELECT pdf_size_bytes FROM simple_validation_requests WHERE id = validation_id),
  'steps', '[]'::jsonb
)
WHERE id = '<job-id>';
```

### Trace Job Execution
```sql
-- Full trace of a specific job
SELECT 
  q.*,
  v.pdf_path,
  v.pdf_size_bytes,
  v.manager_signature IS NOT NULL as has_signature,
  LENGTH(v.manager_signature) as signature_size
FROM pdf_regeneration_queue q
JOIN simple_validation_requests v ON v.id = q.validation_id
WHERE q.id = '<job-id>';
```

### Performance Analysis
```sql
-- Analyze processing time by PDF size
SELECT 
  CASE 
    WHEN v.pdf_size_bytes < 1024 * 1024 THEN '<1MB'
    WHEN v.pdf_size_bytes < 5 * 1024 * 1024 THEN '1-5MB'
    WHEN v.pdf_size_bytes < 10 * 1024 * 1024 THEN '5-10MB'
    ELSE '>10MB'
  END as size_category,
  COUNT(*) as job_count,
  AVG(EXTRACT(EPOCH FROM (q.processed_at - q.created_at))) as avg_seconds,
  MAX(EXTRACT(EPOCH FROM (q.processed_at - q.created_at))) as max_seconds
FROM pdf_regeneration_queue q
JOIN simple_validation_requests v ON v.id = q.validation_id
WHERE q.status = 'completed'
GROUP BY size_category
ORDER BY 
  CASE size_category
    WHEN '<1MB' THEN 1
    WHEN '1-5MB' THEN 2
    WHEN '5-10MB' THEN 3
    ELSE 4
  END;
```

## Maintenance Procedures

### Weekly Maintenance Checklist
1. Review and clear failed jobs older than 7 days
2. Analyze error patterns and update error handling
3. Check storage usage and clean up orphaned files
4. Review performance metrics and optimize if needed
5. Update monitoring thresholds based on trends

### Monthly Review
1. Analyze success rates and processing times
2. Review and optimize PDF positioning coordinates
3. Update documentation based on new issues
4. Plan capacity for expected growth
5. Review security and access controls