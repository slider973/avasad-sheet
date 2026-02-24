import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// This function should be called by a cron job (e.g., daily)
// It checks for expired validation requests and marks them accordingly.

serve(async (req) => {
  try {
    // Verify this is called with the service role key (cron job)
    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.includes(Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "no-match")) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
    );

    const now = new Date().toISOString();

    // Find expired validations
    const { data: expired, error: fetchError } = await supabase
      .from("validation_requests")
      .select("id, employee_id, manager_id")
      .eq("status", "pending")
      .lt("expires_at", now);

    if (fetchError) {
      return new Response(JSON.stringify({ error: fetchError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!expired || expired.length === 0) {
      return new Response(
        JSON.stringify({ message: "No expired validations found", count: 0 }),
        { status: 200, headers: { "Content-Type": "application/json" } },
      );
    }

    // Mark them as expired
    const expiredIds = expired.map((v: { id: string }) => v.id);
    const { error: updateError } = await supabase
      .from("validation_requests")
      .update({ status: "expired" })
      .in_("id", expiredIds);

    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Notify employees about expiration
    const notifications = expired.map((v: { id: string; employee_id: string }) => ({
      user_id: v.employee_id,
      type: "validation_expiring",
      title: "Validation expirée",
      message:
        "Votre demande de validation a expiré car elle n'a pas été traitée dans les 30 jours.",
      data: JSON.stringify({ validation_id: v.id }),
    }));

    if (notifications.length > 0) {
      await supabase.from("notifications").insert(notifications);
    }

    return new Response(
      JSON.stringify({
        message: `${expired.length} validations marked as expired`,
        count: expired.length,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
