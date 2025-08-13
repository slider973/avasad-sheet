import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { PDFDocument, rgb, StandardFonts } from 'https://cdn.skypack.dev/pdf-lib@1.17.1'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    )

    // Get request body
    const { validationId } = await req.json()

    if (!validationId) {
      throw new Error('Validation ID is required')
    }

    // 1. Fetch validation details
    const { data: validation, error: validationError } = await supabaseClient
      .from('simple_validation_requests')
      .select('*')
      .eq('id', validationId)
      .single()

    if (validationError || !validation) {
      throw new Error('Validation not found')
    }

    if (!validation.manager_signature) {
      throw new Error('No manager signature found')
    }

    // 2. Download the original PDF from storage
    const { data: pdfData, error: downloadError } = await supabaseClient
      .storage
      .from('validation-pdfs')
      .download(validation.pdf_path)

    if (downloadError || !pdfData) {
      throw new Error('Failed to download PDF')
    }

    // 3. Load the PDF
    const pdfBytes = await pdfData.arrayBuffer()
    const pdfDoc = await PDFDocument.load(pdfBytes)
    
    // 4. Get the first page (where signatures are)
    const pages = pdfDoc.getPages()
    const firstPage = pages[0]
    const { width, height } = firstPage.getSize()

    // 5. Decode and embed the manager signature
    const signatureBytes = Uint8Array.from(atob(validation.manager_signature), c => c.charCodeAt(0))
    const signatureImage = await pdfDoc.embedPng(signatureBytes)
    const signatureDims = signatureImage.scale(0.3) // Adjust scale as needed

    // 6. Calculate signature position (adjust these values based on your PDF layout)
    // This assumes the signature should be in the bottom right area
    const signatureX = width - 200 // 200 pixels from right
    const signatureY = 100 // 100 pixels from bottom

    // Draw the signature
    firstPage.drawImage(signatureImage, {
      x: signatureX,
      y: signatureY,
      width: signatureDims.width,
      height: signatureDims.height,
    })

    // 7. Add timestamp text if needed
    const helveticaFont = await pdfDoc.embedFont(StandardFonts.Helvetica)
    const fontSize = 8
    const validatedDate = new Date(validation.validated_at).toLocaleDateString('fr-FR')
    
    firstPage.drawText(`Validé le ${validatedDate}`, {
      x: signatureX,
      y: signatureY - 20,
      size: fontSize,
      font: helveticaFont,
      color: rgb(0, 0, 0),
    })

    // 8. Save the modified PDF
    const modifiedPdfBytes = await pdfDoc.save()

    // 9. Generate new filename with version
    const originalPath = validation.pdf_path
    const pathParts = originalPath.split('/')
    const filename = pathParts[pathParts.length - 1]
    const nameWithoutExt = filename.replace('.pdf', '')
    const newFilename = `${nameWithoutExt}_validated.pdf`
    pathParts[pathParts.length - 1] = newFilename
    const newPath = pathParts.join('/')

    // 10. Upload the modified PDF
    const { error: uploadError } = await supabaseClient
      .storage
      .from('validation-pdfs')
      .upload(newPath, modifiedPdfBytes, {
        contentType: 'application/pdf',
        upsert: true
      })

    if (uploadError) {
      throw new Error('Failed to upload modified PDF')
    }

    // 11. Update the validation record with the new PDF path
    const { error: updateError } = await supabaseClient
      .from('simple_validation_requests')
      .update({ 
        pdf_path: newPath,
        pdf_with_signature: true 
      })
      .eq('id', validationId)

    if (updateError) {
      throw new Error('Failed to update validation record')
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'PDF regenerated with signature',
        newPath: newPath 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      },
    )
  }
})