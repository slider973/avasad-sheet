import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // Handle CORS preflight
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

    // Use service_role key for admin operations
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    // Verify the caller's identity
    const { data: { user: caller }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", ""),
    );

    if (authError || !caller) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get caller's profile to check role
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
    const { email, password, first_name, last_name, organization_id, role } = body;

    // Validate required fields
    if (!email || !password || !first_name || !last_name || !role) {
      return new Response(JSON.stringify({ error: "Missing required fields: email, password, first_name, last_name, role" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Validate role value
    const validRoles = ["employee", "manager", "admin", "org_admin", "super_admin"];
    if (!validRoles.includes(role)) {
      return new Response(JSON.stringify({ error: `Invalid role. Must be one of: ${validRoles.join(", ")}` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // org_admin restrictions
    if (isOrgAdmin && !isSuperAdmin) {
      // org_admin can only create employee or manager in their own org tree
      if (!["employee", "manager"].includes(role)) {
        return new Response(JSON.stringify({ error: "org_admin can only create employee or manager roles" }), {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Fetch child org IDs to allow creating users in child orgs
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

    // super_admin creating org_admin or super_admin requires organization_id for org_admin
    if (role === "org_admin" && !organization_id) {
      return new Response(JSON.stringify({ error: "organization_id is required for org_admin role" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Determine the target organization
    const targetOrgId = organization_id || callerProfile.organization_id;

    // Create the auth user
    const { data: newUser, error: createError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        first_name,
        last_name,
      },
    });

    if (createError) {
      return new Response(JSON.stringify({ error: `Failed to create user: ${createError.message}` }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Update the auto-created profile with role and organization
    const { data: profile, error: updateError } = await supabase
      .from("profiles")
      .update({
        first_name,
        last_name,
        organization_id: targetOrgId,
        role,
      })
      .eq("id", newUser.user.id)
      .select()
      .single();

    if (updateError) {
      return new Response(JSON.stringify({ error: `User created but profile update failed: ${updateError.message}` }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ user: newUser.user, profile }), {
      status: 201,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
