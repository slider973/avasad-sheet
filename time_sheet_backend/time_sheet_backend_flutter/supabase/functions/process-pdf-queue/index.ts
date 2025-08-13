import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // 1. Get pending jobs from queue
    const { data: pendingJobs, error: queueError } = await supabaseClient
      .from('pdf_regeneration_queue')
      .select('*')
      .eq('status', 'pending')
      .order('created_at', { ascending: true })
      .limit(10) // Process up to 10 at a time

    if (queueError) {
      throw new Error('Failed to fetch queue: ' + queueError.message)
    }

    const results = []

    // 2. Process each job
    for (const job of pendingJobs || []) {
      try {
        // Mark as processing
        await supabaseClient
          .from('pdf_regeneration_queue')
          .update({ status: 'processing' })
          .eq('id', job.id)

        // Call the regeneration function
        const response = await fetch(
          `${Deno.env.get('SUPABASE_URL')}/functions/v1/regenerate-pdf-with-signature`,
          {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ validationId: job.validation_id }),
          }
        )

        const result = await response.json()

        if (response.ok) {
          // Mark as completed
          await supabaseClient
            .from('pdf_regeneration_queue')
            .update({ 
              status: 'completed',
              processed_at: new Date().toISOString()
            })
            .eq('id', job.id)

          results.push({ jobId: job.id, status: 'success', result })
        } else {
          throw new Error(result.error || 'PDF regeneration failed')
        }

      } catch (error) {
        // Mark as failed
        await supabaseClient
          .from('pdf_regeneration_queue')
          .update({ 
            status: 'failed',
            processed_at: new Date().toISOString(),
            error_message: error.message
          })
          .eq('id', job.id)

        results.push({ jobId: job.id, status: 'failed', error: error.message })
      }
    }

    return new Response(
      JSON.stringify({ 
        success: true,
        processed: results.length,
        results 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})