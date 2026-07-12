import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Verify caller
    const { data: { user: caller }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", ""),
    );
    if (authError || !caller) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { data: callerProfile, error: profileError } = await supabase
      .from("profiles")
      .select("role, organization_id")
      .eq("id", caller.id)
      .single();

    if (profileError || !callerProfile) {
      return new Response(JSON.stringify({ error: "Caller profile not found" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const isSuperAdmin = callerProfile.role === "super_admin";
    const isOrgAdmin = callerProfile.role === "org_admin";

    if (!isSuperAdmin && !isOrgAdmin) {
      return new Response(JSON.stringify({ error: "Insufficient permissions. Must be super_admin or org_admin." }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { email, first_name, last_name, organization_id, role } = body;

    if (!email || !first_name || !last_name || !role) {
      return new Response(JSON.stringify({ error: "Missing required fields: email, first_name, last_name, role" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const validRoles = ["employee", "manager", "admin", "org_admin", "super_admin"];
    if (!validRoles.includes(role)) {
      return new Response(JSON.stringify({ error: `Invalid role. Must be one of: ${validRoles.join(", ")}` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // org_admin restrictions
    if (isOrgAdmin && !isSuperAdmin) {
      if (!["employee", "manager"].includes(role)) {
        return new Response(JSON.stringify({ error: "org_admin can only create employee or manager roles" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      const { data: childOrgs } = await supabase
        .from("organizations")
        .select("id")
        .eq("parent_id", callerProfile.organization_id);

      const allowedOrgIds = [
        callerProfile.organization_id,
        ...(childOrgs?.map((o: { id: string }) => o.id) ?? []),
      ];

      const targetOrgId = organization_id || callerProfile.organization_id;
      if (!allowedOrgIds.includes(targetOrgId)) {
        return new Response(JSON.stringify({ error: "org_admin can only create users in their own organization or child organizations" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }
    }

    if (role === "org_admin" && !organization_id) {
      return new Response(JSON.stringify({ error: "organization_id is required for org_admin role" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const targetOrgId = organization_id || callerProfile.organization_id;

    // 1. Create user with random password
    const randomPassword = crypto.randomUUID() + crypto.randomUUID();
    const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
      email,
      password: randomPassword,
      email_confirm: true,
      user_metadata: { first_name, last_name },
    });

    if (createError) {
      return new Response(JSON.stringify({ error: `Failed to create user: ${createError.message}` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Update profile with role and organization
    const { data: profile, error: updateError } = await supabase
      .from("profiles")
      .update({ first_name, last_name, organization_id: targetOrgId, role })
      .eq("id", newUser.user.id)
      .select()
      .single();

    if (updateError) {
      return new Response(JSON.stringify({ error: `User created but profile update failed: ${updateError.message}` }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Generate recovery link to get the token_hash
    const siteUrl = Deno.env.get("GOTRUE_SITE_URL") || "https://timesheet.staticflow.ch";
    const { data: linkData, error: linkError } = await supabase.auth.admin.generateLink({
      type: "recovery",
      email,
      options: { redirectTo: siteUrl + "/set-password" },
    });

    if (linkError) {
      return new Response(JSON.stringify({ error: `User created but invite link generation failed: ${linkError.message}` }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 4. Send invite email via Resend
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const inviteUrl = `${siteUrl}/set-password?token_hash=${linkData.properties.hashed_token}&type=recovery`;

    const emailHtml = `
      <div style="font-family: 'Helvetica Neue', Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 40px 20px;">
        <div style="text-align: center; margin-bottom: 32px;">
          <div style="display: inline-flex; align-items: center; justify-content: center; width: 48px; height: 48px; background: linear-gradient(135deg, #6366f1, #8b5cf6); border-radius: 12px; margin-bottom: 12px;">
            <span style="color: white; font-weight: 800; font-size: 18px;">TS</span>
          </div>
          <h2 style="margin: 0; color: #1a1a1a;">TimeSheet</h2>
        </div>
        <h1 style="font-size: 24px; color: #1a1a1a; margin-bottom: 16px;">Bienvenue ${first_name} !</h1>
        <p style="color: #666; font-size: 15px; line-height: 1.6;">
          Vous avez ete invite a rejoindre TimeSheet. Cliquez sur le bouton ci-dessous pour definir votre mot de passe et acceder a votre espace.
        </p>
        <div style="text-align: center; margin: 32px 0;">
          <a href="${inviteUrl}" style="display: inline-block; background: linear-gradient(135deg, #6366f1, #8b5cf6); color: white; text-decoration: none; padding: 14px 32px; border-radius: 8px; font-weight: 600; font-size: 15px;">
            Definir mon mot de passe
          </a>
        </div>
        <p style="color: #999; font-size: 13px; line-height: 1.5;">
          Si vous n'attendiez pas cette invitation, vous pouvez ignorer cet email.
        </p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 32px 0;" />
        <p style="color: #bbb; font-size: 12px; text-align: center;">TimeSheet — Gestion du temps</p>
      </div>
    `;

    // L'utilisateur est créé à ce stade : on renvoie 201 quoi qu'il arrive,
    // mais la réponse dit explicitement si l'email d'invitation est parti
    // (emailSent) et pourquoi il n'est pas parti le cas échéant (emailError).
    let emailSent = false;
    let emailError: string | null = null;

    if (!resendApiKey) {
      emailError = "RESEND_API_KEY non configurée : email d'invitation non envoyé";
      console.error(`create-user: RESEND_API_KEY missing, invite email not sent to ${email}`);
    } else {
      try {
        const resendRes = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${resendApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from: "TimeSheet <noreply@staticflow.ch>",
            to: [email],
            subject: `${first_name}, bienvenue sur TimeSheet`,
            html: emailHtml,
          }),
        });

        if (resendRes.ok) {
          emailSent = true;
        } else {
          const resendBody = await resendRes.text();
          console.error(`create-user: Resend API error (${resendRes.status}): ${resendBody}`);
          emailError = "L'envoi de l'email d'invitation a échoué (fournisseur email)";
        }
      } catch (e) {
        console.error("create-user: Resend request failed:", e);
        emailError = "L'envoi de l'email d'invitation a échoué (erreur réseau)";
      }
    }

    return new Response(
      JSON.stringify({
        user: newUser.user,
        profile,
        invited: emailSent,
        emailSent,
        emailError,
      }),
      {
        status: 201,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("create-user: unexpected error:", err);
    return new Response(JSON.stringify({ error: "Erreur interne du serveur" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
