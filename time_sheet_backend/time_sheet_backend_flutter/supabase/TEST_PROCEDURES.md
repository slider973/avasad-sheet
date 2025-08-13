# PDF Regeneration Test Procedures

## Test Environment Setup

### Prerequisites
1. Deploy functions as per DEPLOYMENT.md
2. Have at least one manager account with a signature configured
3. Have at least one employee account with timesheets to validate

### Test Data Preparation

1. **Create Test Manager**:
   ```sql
   -- Insert a test manager (if not exists)
   INSERT INTO simple_managers (id, email, first_name, last_name, company)
   VALUES (
     gen_random_uuid(),
     'test.manager@company.com',
     'Test',
     'Manager',
     'TestCompany'
   ) ON CONFLICT (email) DO NOTHING;
   ```

2. **Create Test Employee Validation**:
   - Log in as an employee
   - Generate a timesheet for the current month
   - Create a validation request
   - Note the validation ID

## Test Scenarios

### Test 1: Basic PDF Regeneration

**Objective**: Verify that approving a validation triggers PDF regeneration with manager signature

**Steps**:
1. As a manager, navigate to the validation detail page
2. Ensure your signature is loaded (visible in the signature area)
3. Add an optional comment
4. Click "Approuver"
5. Wait for confirmation message

**Verification**:
```sql
-- Check queue entry was created
SELECT * FROM pdf_regeneration_queue 
WHERE validation_id = '<validation-id>'
ORDER BY created_at DESC;

-- Check validation status
SELECT id, status, manager_signature IS NOT NULL as has_signature, pdf_with_signature
FROM simple_validation_requests 
WHERE id = '<validation-id>';
```

**Expected Result**:
- Queue entry created with status 'pending'
- Validation status is 'approved'
- manager_signature is not null
- pdf_with_signature initially false

### Test 2: Queue Processing

**Objective**: Verify the queue processor successfully regenerates PDFs

**Steps**:
1. Manually trigger the queue processor:
   ```bash
   curl -X POST https://<project-ref>.supabase.co/functions/v1/process-pdf-queue \
     -H "Authorization: Bearer <service-role-key>" \
     -H "Content-Type: application/json" \
     -d '{}'
   ```

2. Check the response for successful processing

**Verification**:
```sql
-- Check queue status
SELECT * FROM pdf_regeneration_queue 
WHERE validation_id = '<validation-id>';

-- Check PDF path was updated
SELECT pdf_path, pdf_with_signature 
FROM simple_validation_requests 
WHERE id = '<validation-id>';

-- List files in storage
SELECT name, created_at 
FROM storage.objects 
WHERE bucket_id = 'validation-pdfs' 
AND name LIKE '%_validated.pdf'
ORDER BY created_at DESC;
```

**Expected Result**:
- Queue entry status is 'completed'
- pdf_path ends with '_validated.pdf'
- pdf_with_signature is true
- New PDF file exists in storage

### Test 3: PDF Content Verification

**Objective**: Verify the regenerated PDF contains the manager signature

**Steps**:
1. Download the original PDF:
   ```bash
   curl -o original.pdf \
     "https://<project-ref>.supabase.co/storage/v1/object/public/validation-pdfs/<original-path>"
   ```

2. Download the validated PDF:
   ```bash
   curl -o validated.pdf \
     "https://<project-ref>.supabase.co/storage/v1/object/public/validation-pdfs/<validated-path>"
   ```

3. Open both PDFs and compare

**Expected Result**:
- Validated PDF contains manager signature image
- Validated PDF shows "Validé le [date]" text
- All original content is preserved

### Test 4: Error Handling

**Objective**: Test error scenarios and recovery

#### Test 4.1: Invalid Validation ID
```bash
curl -X POST https://<project-ref>.supabase.co/functions/v1/regenerate-pdf-with-signature \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{"validationId": "invalid-uuid"}'
```

**Expected**: Error response "Validation not found"

#### Test 4.2: Missing Manager Signature
1. Manually update a validation to approved without signature:
   ```sql
   UPDATE simple_validation_requests 
   SET status = 'approved', manager_signature = NULL 
   WHERE id = '<validation-id>';
   ```

2. Trigger regeneration

**Expected**: Error "No manager signature found"

#### Test 4.3: Missing PDF File
1. Create validation with non-existent PDF path:
   ```sql
   UPDATE simple_validation_requests 
   SET pdf_path = 'non-existent/file.pdf' 
   WHERE id = '<validation-id>';
   ```

2. Trigger regeneration

**Expected**: Error "Failed to download PDF"

### Test 5: Concurrent Processing

**Objective**: Verify multiple validations can be processed concurrently

**Steps**:
1. Create 5 approved validations with signatures
2. Insert them all into the queue:
   ```sql
   INSERT INTO pdf_regeneration_queue (validation_id)
   SELECT id FROM simple_validation_requests 
   WHERE status = 'approved' 
   AND manager_signature IS NOT NULL
   AND pdf_with_signature = false
   LIMIT 5;
   ```

3. Trigger the processor
4. Monitor processing

**Verification**:
```sql
-- Monitor progress
SELECT status, COUNT(*) 
FROM pdf_regeneration_queue 
WHERE created_at > NOW() - INTERVAL '5 minutes'
GROUP BY status;
```

**Expected Result**:
- All 5 jobs processed successfully
- No timeouts or conflicts

### Test 6: UI Integration

**Objective**: Verify the UI correctly displays regenerated PDFs

**Steps**:
1. As an employee, view a validated timesheet
2. Click download PDF
3. Verify the downloaded PDF contains the manager signature

**Expected Result**:
- PDF downloads successfully
- Manager signature is visible in the PDF
- Validation date is shown

## Performance Testing

### Load Test
```bash
# Create 50 test validations
for i in {1..50}; do
  # Insert test validation
  psql -c "INSERT INTO pdf_regeneration_queue (validation_id) VALUES ('<valid-id>');"
done

# Trigger processor and measure time
time curl -X POST https://<project-ref>.supabase.co/functions/v1/process-pdf-queue \
  -H "Authorization: Bearer <service-role-key>" \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Monitoring Metrics
```sql
-- Average processing time
SELECT 
  AVG(EXTRACT(EPOCH FROM (processed_at - created_at))) as avg_seconds,
  MIN(EXTRACT(EPOCH FROM (processed_at - created_at))) as min_seconds,
  MAX(EXTRACT(EPOCH FROM (processed_at - created_at))) as max_seconds
FROM pdf_regeneration_queue
WHERE status = 'completed'
AND processed_at IS NOT NULL;

-- Success rate
SELECT 
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM pdf_regeneration_queue
GROUP BY status;
```

## Automated Test Script

Create a test script `test_pdf_regeneration.sh`:

```bash
#!/bin/bash

PROJECT_REF="<your-project-ref>"
SERVICE_KEY="<your-service-role-key>"
VALIDATION_ID="<test-validation-id>"

echo "🧪 Testing PDF Regeneration System"

# Test 1: Direct function call
echo "📝 Test 1: Direct regeneration function"
RESPONSE=$(curl -s -X POST "https://$PROJECT_REF.supabase.co/functions/v1/regenerate-pdf-with-signature" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"validationId\": \"$VALIDATION_ID\"}")

if [[ $RESPONSE == *"success"* ]]; then
  echo "✅ Direct regeneration successful"
else
  echo "❌ Direct regeneration failed: $RESPONSE"
fi

# Test 2: Queue processor
echo "📝 Test 2: Queue processor"
RESPONSE=$(curl -s -X POST "https://$PROJECT_REF.supabase.co/functions/v1/process-pdf-queue" \
  -H "Authorization: Bearer $SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}')

if [[ $RESPONSE == *"processed"* ]]; then
  echo "✅ Queue processor successful"
else
  echo "❌ Queue processor failed: $RESPONSE"
fi

echo "🎉 Tests completed"
```

## Troubleshooting Guide

### Issue: Signature Not Visible
1. Check signature format is base64 PNG
2. Verify signature positioning coordinates
3. Check PDF page dimensions
4. Review function logs for errors

### Issue: Queue Stuck
1. Check for failed jobs blocking the queue
2. Verify cron job is running
3. Check function timeout settings
4. Review error messages in queue table

### Issue: Performance Degradation
1. Check queue size
2. Monitor function execution time
3. Consider increasing batch size
4. Check storage bucket performance