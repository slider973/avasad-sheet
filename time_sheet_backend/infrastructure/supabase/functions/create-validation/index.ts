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
    const { manager_id, period_start, period_end, pdf_url } = body;

    // Create the validation request
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
      return new Response(JSON.stringify({ error: insertError.message }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
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
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
