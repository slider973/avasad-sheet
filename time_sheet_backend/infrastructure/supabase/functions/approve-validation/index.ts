import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", ""),
    );

    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { validation_id, comment, signed_pdf_url, manager_signature } = body;

    // Verify this manager is authorized for this validation
    const { data: validation, error: fetchError } = await supabase
      .from("validation_requests")
      .select("*")
      .eq("id", validation_id)
      .eq("manager_id", user.id)
      .single();

    if (fetchError || !validation) {
      return new Response(
        JSON.stringify({ error: "Validation non trouvée ou non autorisée" }),
        { status: 404, headers: { "Content-Type": "application/json" } },
      );
    }

    if (validation.status !== "pending") {
      return new Response(
        JSON.stringify({ error: "Cette validation a déjà été traitée" }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    // Determine if there's a client signer configured
    const hasClientSigner = validation.client_signer_name || validation.client_signer_email;

    // Update the validation
    const updateData: Record<string, unknown> = {
      manager_comment: comment || null,
    };

    if (manager_signature) {
      updateData.manager_signature_url = manager_signature;
    }

    if (signed_pdf_url) {
      updateData.pdf_url = signed_pdf_url;
    }

    if (hasClientSigner) {
      // Advance to client signing step instead of completing
      updateData.signing_step = "client";

      // Create a signing token for the client if one doesn't exist
      const { data: existingClientToken } = await supabase
        .from("signing_tokens")
        .select("id, token")
        .eq("validation_id", validation_id)
        .eq("signer_role", "client")
        .single();

      if (!existingClientToken) {
        await supabase.from("signing_tokens").insert({
          validation_id,
          signer_role: "client",
          signer_name: validation.client_signer_name || "Client",
          signer_email: validation.client_signer_email,
        });
      }

      // Also create/update manager signing token as signed
      const { data: managerToken } = await supabase
        .from("signing_tokens")
        .select("id")
        .eq("validation_id", validation_id)
        .eq("signer_role", "manager")
        .single();

      if (!managerToken) {
        // Get manager name
        const { data: managerProfile } = await supabase
          .from("profiles")
          .select("first_name, last_name")
          .eq("id", user.id)
          .single();

        const managerName = managerProfile
          ? `${managerProfile.first_name} ${managerProfile.last_name}`
          : "Manager";

        await supabase.from("signing_tokens").insert({
          validation_id,
          signer_role: "manager",
          signer_name: managerName,
          signer_email: user.email,
          signed_at: new Date().toISOString(),
        });
      } else {
        await supabase
          .from("signing_tokens")
          .update({ signed_at: new Date().toISOString() })
          .eq("id", managerToken.id);
      }
    } else {
      // No client signer, complete the validation
      updateData.status = "approved";
      updateData.validated_at = new Date().toISOString();
      updateData.signing_step = "completed";
    }

    const { data: updated, error: updateError } = await supabase
      .from("validation_requests")
      .update(updateData)
      .eq("id", validation_id)
      .select()
      .single();

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Get manager name for notification
    const { data: managerProfile } = await supabase
      .from("profiles")
      .select("first_name, last_name")
      .eq("id", user.id)
      .single();

    const managerName = managerProfile
      ? `${managerProfile.first_name} ${managerProfile.last_name}`
      : "Votre manager";

    if (hasClientSigner) {
      // Notify employee that manager approved and client signature is pending
      await supabase.from("notifications").insert({
        user_id: validation.employee_id,
        type: "validation_signed",
        title: "Signature manager reçue",
        message: `${managerName} a signé votre relevé. En attente de la signature client.`,
        data: JSON.stringify({ validation_id }),
      });
    } else {
      // Notify the employee of full approval
      await supabase.from("notifications").insert({
        user_id: validation.employee_id,
        type: "validation_approved",
        title: "Validation approuvée",
        message: `${managerName} a approuvé votre demande de validation`,
        data: JSON.stringify({ validation_id }),
      });
    }

    // Include client signing URL in response if applicable
    let clientSigningUrl: string | null = null;
    if (hasClientSigner) {
      const { data: clientToken } = await supabase
        .from("signing_tokens")
        .select("token")
        .eq("validation_id", validation_id)
        .eq("signer_role", "client")
        .single();

      if (clientToken) {
        // Resolve web URL from the organization linked to this validation
        const { data: orgUrl } = await supabase.rpc('get_org_web_url', { p_validation_id: validation_id });
        const webUrl = orgUrl || Deno.env.get("WEB_URL") || "https://timesheet.staticflow.ch";
        clientSigningUrl = `${webUrl}/sign/${clientToken.token}`;
      }
    }

    return new Response(
      JSON.stringify({
        ...updated,
        client_signing_url: clientSigningUrl,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
