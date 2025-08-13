-- Add column to track if PDF has been regenerated with signature
ALTER TABLE simple_validation_requests 
ADD COLUMN IF NOT EXISTS pdf_with_signature BOOLEAN DEFAULT FALSE;

-- Create function to trigger PDF regeneration
CREATE OR REPLACE FUNCTION trigger_pdf_regeneration()
RETURNS TRIGGER AS $$
DECLARE
  response JSONB;
BEGIN
  -- Only trigger if status changed to approved and manager signature exists
  IF NEW.status = 'approved' AND OLD.status != 'approved' AND NEW.manager_signature IS NOT NULL THEN
    -- Call the edge function to regenerate PDF
    SELECT content::JSONB INTO response
    FROM http_post(
      'https://' || current_setting('app.supabase_url') || '/functions/v1/regenerate-pdf-with-signature',
      jsonb_build_object('validationId', NEW.id)::text,
      'application/json',
      jsonb_build_object(
        'Authorization', 'Bearer ' || current_setting('app.supabase_service_role_key'),
        'Content-Type', 'application/json'
      )::text
    );
    
    -- Log the response for debugging
    RAISE NOTICE 'PDF regeneration response: %', response;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS regenerate_pdf_on_approval ON simple_validation_requests;
CREATE TRIGGER regenerate_pdf_on_approval
  AFTER UPDATE ON simple_validation_requests
  FOR EACH ROW
  EXECUTE FUNCTION trigger_pdf_regeneration();

-- Alternative: Use Supabase's built-in webhook functionality
-- This is simpler and doesn't require http extension
CREATE OR REPLACE FUNCTION notify_pdf_regeneration()
RETURNS TRIGGER AS $$
BEGIN
  -- Only notify if status changed to approved and manager signature exists
  IF NEW.status = 'approved' AND OLD.status != 'approved' AND NEW.manager_signature IS NOT NULL THEN
    -- Insert a job into a queue table
    INSERT INTO pdf_regeneration_queue (validation_id, created_at)
    VALUES (NEW.id, NOW());
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create queue table for PDF regeneration jobs
CREATE TABLE IF NOT EXISTS pdf_regeneration_queue (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  validation_id UUID NOT NULL REFERENCES simple_validation_requests(id),
  status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  error_message TEXT
);

-- Create index for efficient queries
CREATE INDEX idx_pdf_regeneration_queue_status ON pdf_regeneration_queue(status);

-- Use this simpler trigger instead
DROP TRIGGER IF EXISTS queue_pdf_regeneration ON simple_validation_requests;
CREATE TRIGGER queue_pdf_regeneration
  AFTER UPDATE ON simple_validation_requests
  FOR EACH ROW
  EXECUTE FUNCTION notify_pdf_regeneration();