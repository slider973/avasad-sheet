import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { decode as base64Decode } from "https://deno.land/std@0.168.0/encoding/base64.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const body = await req.json();
    const { token, signature_data } = body;

    if (!token || !signature_data) {
      return new Response(
        JSON.stringify({ error: "token et signature_data (base64 PNG) sont requis" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Validate the token
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
    if (now > new Date(signingToken.expires_at)) {
      return new Response(
        JSON.stringify({ error: "Token expiré" }),
        { status: 410, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Check if already signed
    if (signingToken.signed_at) {
      return new Response(
        JSON.stringify({ error: "Ce document a déjà été signé", already_signed: true }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Upload signature PNG to Supabase Storage
    const signatureBytes = base64Decode(signature_data);
    const storagePath = `tokens/${signingToken.validation_id}/${signingToken.signer_role}.png`;

    const { error: uploadError } = await supabase.storage
      .from("signatures")
      .upload(storagePath, signatureBytes, {
        contentType: "image/png",
        upsert: true,
      });

    if (uploadError) {
      return new Response(
        JSON.stringify({ error: `Erreur upload signature: ${uploadError.message}` }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Mark token as signed
    await supabase
      .from("signing_tokens")
      .update({
        signed_at: now.toISOString(),
        signature_url: storagePath,
      })
      .eq("id", signingToken.id);

    // Get the validation request
    const { data: validation } = await supabase
      .from("validation_requests")
      .select("*")
      .eq("id", signingToken.validation_id)
      .single();

    if (!validation) {
      return new Response(
        JSON.stringify({ error: "Validation non trouvée" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Update validation based on signer role
    const updateData: Record<string, unknown> = {};

    if (signingToken.signer_role === "manager") {
      updateData.manager_signature_url = storagePath;

      // If there's a client signer configured, advance to client step
      if (validation.client_signer_email || validation.client_signer_name) {
        updateData.signing_step = "client";

        // Auto-generate token for client if email is set
        if (validation.client_signer_name) {
          const { data: clientToken } = await supabase
            .from("signing_tokens")
            .select("id")
            .eq("validation_id", validation.id)
            .eq("signer_role", "client")
            .single();

          if (!clientToken) {
            await supabase.from("signing_tokens").insert({
              validation_id: validation.id,
              signer_role: "client",
              signer_name: validation.client_signer_name,
              signer_email: validation.client_signer_email,
            });
          }
        }
      } else {
        // No client signer, mark as completed
        updateData.signing_step = "completed";
        updateData.status = "approved";
        updateData.validated_at = now.toISOString();
      }
    } else if (signingToken.signer_role === "client") {
      // Client is the final signer
      updateData.signing_step = "completed";
      updateData.status = "approved";
      updateData.validated_at = now.toISOString();
    }

    if (Object.keys(updateData).length > 0) {
      await supabase
        .from("validation_requests")
        .update(updateData)
        .eq("id", validation.id);
    }

    // Notify employee
    const signerLabel = signingToken.signer_role === "manager" ? "Le manager" : "Le client";
    await supabase.from("notifications").insert({
      user_id: validation.employee_id,
      type: signingToken.signer_role === "client" && updateData.status === "approved"
        ? "validation_approved"
        : "validation_signed",
      title: updateData.status === "approved"
        ? "Validation complète"
        : "Signature reçue",
      message: updateData.status === "approved"
        ? `Toutes les signatures ont été collectées. Votre relevé d'heures est validé.`
        : `${signerLabel} (${signingToken.signer_name}) a signé votre relevé d'heures.`,
      data: JSON.stringify({ validation_id: validation.id }),
    });

    // Determine next step info for the response
    let nextStep: string | null = null;
    if (updateData.signing_step === "client") {
      const { data: clientToken } = await supabase
        .from("signing_tokens")
        .select("token")
        .eq("validation_id", validation.id)
        .eq("signer_role", "client")
        .single();

      if (clientToken) {
        // Resolve web URL from the organization linked to this validation
        const { data: orgUrl } = await supabase.rpc('get_org_web_url', { p_validation_id: validation.id });
        const webUrl = orgUrl || Deno.env.get("WEB_URL") || "https://timesheet.staticflow.ch";
        nextStep = `${webUrl}/sign/${clientToken.token}`;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        next_step: updateData.signing_step ?? validation.signing_step,
        completed: updateData.status === "approved",
        next_signing_url: nextStep,
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
