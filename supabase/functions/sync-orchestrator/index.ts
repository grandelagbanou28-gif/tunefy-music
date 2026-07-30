import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const FUNCTIONS_BASE = "https://your-project.supabase.co/functions/v1";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "POST only" }), { status: 405 });
  }

  const start = Date.now();
  const orchestratorLog: Record<string, any> = {
    source: "orchestrator",
    started_at: new Date().toISOString(),
    status: "running",
    syncs: {},
  };

  const syncs = [
    { name: "jamendo", url: `${FUNCTIONS_BASE}/sync-jamendo` },
    { name: "audius", url: `${FUNCTIONS_BASE}/sync-audius` },
    { name: "youtube", url: `${FUNCTIONS_BASE}/sync-youtube` },
    { name: "itunes", url: `${FUNCTIONS_BASE}/sync-itunes` },
  ];

  const results = await Promise.allSettled(
    syncs.map(async (s) => {
      const syncStart = Date.now();
      try {
        const res = await fetch(s.url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ triggered_by: "orchestrator" }),
        }).timeout(new Date(Date.now() + 300000));

        const body = await res.json().catch(() => null);
        return {
          name: s.name,
          status: res.ok ? (body?.status || "unknown") : "http_error",
          duration_ms: Date.now() - syncStart,
          error: body?.error_message || null,
        };
      } catch (e: any) {
        return {
          name: s.name,
          status: "failed",
          duration_ms: Date.now() - syncStart,
          error: e.message,
        };
      }
    })
  );

  for (const result of results) {
    if (result.status === "fulfilled" && result.value) {
      orchestratorLog.syncs[result.value.name] = result.value;
    }
  }

  const allSuccess = Object.values(orchestratorLog.syncs).every((s: any) => s.status === "success");
  const anyFailed = Object.values(orchestratorLog.syncs).some((s: any) => s.status === "failed");

  orchestratorLog.status = allSuccess ? "success" : anyFailed ? "partial_failure" : "failed";
  orchestratorLog.finished_at = new Date().toISOString();
  orchestratorLog.duration_ms = Date.now() - start;

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_KEY")!;

    await fetch(`${supabaseUrl}/rest/v1/sync_logs`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
      body: JSON.stringify(orchestratorLog),
    }).catch(() => {});
  } catch (_) {}

  return new Response(JSON.stringify(orchestratorLog), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});