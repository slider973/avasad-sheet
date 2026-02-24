import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const token = url.searchParams.get("token");

    if (!token) {
      return new Response(
        JSON.stringify({ error: "Token requis" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Look up the signing token
    const { data: signingToken, error: tokenError } = await supabase
      .from("signing_tokens")
      .select("*")
      .eq("token", token)
      .single();

    if (tokenError || !signingToken) {
      return new Response(
        JSON.stringify({ error: "Token invalide" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Check expiry
    const now = new Date();
    const expiresAt = new Date(signingToken.expires_at);
    if (now > expiresAt) {
      return new Response(
        JSON.stringify({
          error: "Token expiré",
          expired: true,
          signer_name: signingToken.signer_name,
          signer_role: signingToken.signer_role,
        }),
        { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Check if already signed
    if (signingToken.signed_at) {
      return new Response(
        JSON.stringify({
          already_signed: true,
          signed_at: signingToken.signed_at,
          signer_name: signingToken.signer_name,
          signer_role: signingToken.signer_role,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Fetch validation details
    const { data: validation, error: valError } = await supabase
      .from("validation_requests")
      .select("id, period_start, period_end, employee_id, pdf_url, signing_step")
      .eq("id", signingToken.validation_id)
      .single();

    if (valError || !validation) {
      return new Response(
        JSON.stringify({ error: "Validation non trouvée" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Fetch employee name
    const { data: employeeProfile } = await supabase
      .from("profiles")
      .select("first_name, last_name")
      .eq("id", validation.employee_id)
      .single();

    const employeeName = employeeProfile
      ? `${employeeProfile.first_name ?? ""} ${employeeProfile.last_name ?? ""}`.trim()
      : "Employé";

    // Generate a temporary signed URL for the PDF (valid 1 hour)
    let pdfSignedUrl: string | null = null;
    if (validation.pdf_url) {
      const { data: urlData } = await supabase.storage
        .from("pdfs")
        .createSignedUrl(validation.pdf_url, 3600);
      pdfSignedUrl = urlData?.signedUrl ?? null;
    }

    // Get all signing tokens for this validation to show progress
    const { data: allTokens } = await supabase
      .from("signing_tokens")
      .select("signer_role, signer_name, signed_at")
      .eq("validation_id", signingToken.validation_id)
      .order("created_at", { ascending: true });

    return new Response(
      JSON.stringify({
        validation_id: validation.id,
        signer_role: signingToken.signer_role,
        signer_name: signingToken.signer_name,
        period_start: validation.period_start,
        period_end: validation.period_end,
        employee_name: employeeName,
        pdf_url: pdfSignedUrl,
        signing_step: validation.signing_step,
        already_signed: false,
        expired: false,
        signers: allTokens ?? [],
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: err.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
