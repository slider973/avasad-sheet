import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };

// Rôles autorisés à recevoir une demande de validation.
// Aligné sur la RPC get_managers_for_employee (migration 00011) qui alimente
// le sélecteur de manager côté client.
const MANAGER_ROLES = ["manager", "admin", "org_admin", "super_admin"];

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: jsonHeaders,
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
        headers: jsonHeaders,
      });
    }

    const body = await req.json();
    const { manager_id, period_start, period_end, pdf_url } = body;

    if (!manager_id || !period_start || !period_end) {
      return new Response(
        JSON.stringify({ error: "manager_id, period_start et period_end sont requis" }),
        { status: 400, headers: jsonHeaders },
      );
    }

    // ------------------------------------------------------------------
    // Validation serveur du manager_id (la fonction tourne en service_role
    // et bypasse le RLS : sans ces contrôles, un employé pourrait désigner
    // n'importe qui comme manager et contourner la migration 00015).
    // ------------------------------------------------------------------

    // Cohérent avec 00015 : un employé ne peut pas s'auto-désigner manager.
    if (manager_id === user.id) {
      return new Response(
        JSON.stringify({ error: "Vous ne pouvez pas être votre propre manager" }),
        { status: 400, headers: jsonHeaders },
      );
    }

    // Le manager doit exister, être actif, avoir un rôle de manager, et
    // appartenir à la MÊME organisation que l'employé (strict : la RPC
    // get_managers_for_employee ne propose que les managers de la même org,
    // pas ceux des orgs enfants).
    const [{ data: callerProfile }, { data: managerProfile }] = await Promise.all([
      supabase
        .from("profiles")
        .select("organization_id")
        .eq("id", user.id)
        .single(),
      supabase
        .from("profiles")
        .select("role, organization_id, is_active")
        .eq("id", manager_id)
        .single(),
    ]);

    if (!managerProfile || managerProfile.is_active === false ||
        !MANAGER_ROLES.includes(managerProfile.role)) {
      return new Response(
        JSON.stringify({ error: "Manager invalide" }),
        { status: 400, headers: jsonHeaders },
      );
    }

    if (!callerProfile?.organization_id ||
        callerProfile.organization_id !== managerProfile.organization_id) {
      return new Response(
        JSON.stringify({ error: "Le manager doit appartenir à votre organisation" }),
        { status: 403, headers: jsonHeaders },
      );
    }

    // Create the validation request (status forcé à 'pending')
    const { data: validation, error: insertError } = await supabase
      .from("validation_requests")
      .insert({
        employee_id: user.id,
        manager_id,
        period_start,
        period_end,
        pdf_url,
        status: "pending",
      })
      .select()
      .single();

    if (insertError) {
      console.error("create-validation: insert failed:", insertError.message);
      return new Response(JSON.stringify({ error: "Impossible de créer la validation" }), {
        status: 400,
        headers: jsonHeaders,
      });
    }

    // Get employee profile for notification
    const { data: profile } = await supabase
      .from("profiles")
      .select("first_name, last_name")
      .eq("id", user.id)
      .single();

    const employeeName = profile
      ? `${profile.first_name} ${profile.last_name}`
      : "Un employé";

    // Create notification for the manager
    await supabase.from("notifications").insert({
      user_id: manager_id,
      type: "validation_created",
      title: "Nouvelle demande de validation",
      message: `${employeeName} a soumis une demande de validation pour la période ${period_start} - ${period_end}`,
      data: JSON.stringify({
        validation_id: validation.id,
        employee_id: user.id,
      }),
    });

    return new Response(JSON.stringify(validation), {
      status: 200,
      headers: jsonHeaders,
    });
  } catch (err) {
    console.error("create-validation: unexpected error:", err);
    return new Response(JSON.stringify({ error: "Erreur interne du serveur" }), {
      status: 500,
      headers: jsonHeaders,
    });
  }
});
