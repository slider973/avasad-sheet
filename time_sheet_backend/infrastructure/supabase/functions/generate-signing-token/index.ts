import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
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
    const { validation_id, next_signer_role, signer_name, signer_email, source_token } = body;

    if (!validation_id || !next_signer_role || !signer_name) {
      return new Response(
        JSON.stringify({ error: "validation_id, next_signer_role et signer_name sont requis" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!["manager", "client"].includes(next_signer_role)) {
      return new Response(
        JSON.stringify({ error: "next_signer_role doit être 'manager' ou 'client'" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Authenticate: either via Bearer token (Supabase user) or via source_token (chaining)
    let authorized = false;

    const authHeader = req.headers.get("Authorization");
    if (authHeader) {
      const { data: { user }, error: authError } = await supabase.auth.getUser(
        authHeader.replace("Bearer ", ""),
      );
      if (!authError && user) {
        // Verify the user is the employee or manager of this validation
        const { data: validation } = await supabase
          .from("validation_requests")
          .select("employee_id, manager_id")
          .eq("id", validation_id)
          .single();

        if (validation && (validation.employee_id === user.id || validation.manager_id === user.id)) {
          authorized = true;
        }
      }
    }

    if (!authorized && source_token) {
      // Verify the source token is valid and signed
      const { data: srcToken } = await supabase
        .from("signing_tokens")
        .select("*")
        .eq("token", source_token)
        .eq("validation_id", validation_id)
        .not("signed_at", "is", null)
        .single();

      if (srcToken) {
        authorized = true;
      }
    }

    if (!authorized) {
      return new Response(
        JSON.stringify({ error: "Non autorisé" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Check that a token doesn't already exist for this role+validation
    const { data: existingToken } = await supabase
      .from("signing_tokens")
      .select("id, token")
      .eq("validation_id", validation_id)
      .eq("signer_role", next_signer_role)
      .single();

    if (existingToken) {
      // Return the existing token instead of creating a new one
      const webUrl = Deno.env.get("WEB_URL") ?? "https://timesheet.heytalent.ch";
      return new Response(
        JSON.stringify({
          token: existingToken.token,
          signing_url: `${webUrl}/sign/${existingToken.token}`,
        }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Create the signing token
    const { data: newToken, error: insertError } = await supabase
      .from("signing_tokens")
      .insert({
        validation_id,
        signer_role: next_signer_role,
        signer_name: signer_name,
        signer_email: signer_email || null,
      })
      .select()
      .single();

    if (insertError || !newToken) {
      return new Response(
        JSON.stringify({ error: insertError?.message ?? "Erreur lors de la création du token" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Update the signing step on validation_requests
    await supabase
      .from("validation_requests")
      .update({ signing_step: next_signer_role })
      .eq("id", validation_id);

    const webUrl = Deno.env.get("WEB_URL") ?? "https://timesheet.heytalent.ch";
    const signingUrl = `${webUrl}/sign/${newToken.token}`;

    return new Response(
      JSON.stringify({
        token: newToken.token,
        signing_url: signingUrl,
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
