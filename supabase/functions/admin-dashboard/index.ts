import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseKey = Deno.env.get("SUPABASE_SERVICE_KEY")!;

  if (req.method === "OPTIONS") {
    return new Response("", {
      status: 200,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "*",
      },
    });
  }

  try {
    const url = new URL(req.url!);
    const action = url.searchParams.get("action");

    if (action === "status") {
      const { data: lastSync } = await fetch(
        `${supabaseUrl}/rest/v1/sync_logs?select=*&order=started_at.desc&limit=20`,
        {
          headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
        }
      ).then((r) => r.json()).catch(() => null);

      const { data: config } = await fetch(
        `${supabaseUrl}/rest/v1/sync_config?select=*`,
        {
          headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
        }
      ).then((r) => r.json()).catch(() => null);

      const { count: albumCount } = await fetch(
        `${supabaseUrl}/rest/v1/albums?select=count`,
        {
          headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
        }
      ).then((r) => r.json().catch(() => ({ count: 0 })) as any);

      const { count: trackCount } = await fetch(
        `${supabaseUrl}/rest/v1/tracks?select=count`,
        {
          headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
        }
      ).then((r) => r.json().catch(() => ({ count: 0 })) as any);

      const { count: playlistCount } = await fetch(
        `${supabaseUrl}/rest/v1/playlists?select=count`,
        {
          headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
        }
      ).then((r) => r.json().catch(() => ({ count: 0 })) as any);

      const status: any = {
        last_syncs: lastSync,
        config: config,
        totals: { albums: albumCount, tracks: trackCount, playlists: playlistCount },
        sources: ["jamendo", "audius", "youtube", "itunes"],
        server_time: new Date().toISOString(),
      };

      return new Response(JSON.stringify(status, null, 2), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (action === "trigger") {
      const source = url.searchParams.get("source");
      if (!source) {
        return new Response(JSON.stringify({ error: "source parameter required" }), { status: 400 });
      }

      const functionUrl = `${FUNCTIONS_BASE}/sync-${source}`;
      const res = await fetch(functionUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ triggered_by: "admin" }),
      }).timeout(new Date(Date.now() + 300000));

      const body = await res.json().catch(() => null);
      return new Response(JSON.stringify(body), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!action) {
      const { data: lastSync } = await fetch(
        `${supabaseUrl}/rest/v1/sync_logs?select=source,started_at,finished_at,status,albums_found,albums_added,tracks_found,tracks_added,playlists_found,playlists_added,error_message&order=started_at.desc&limit=10`,
        {
          headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
        }
      ).then((r) => r.json()).catch(() => null);

      const html = `<!DOCTYPE html><html><head><title>Tunefy Sync Admin</title><style>
        body { font-family: sans-serif; margin: 20px; background: #1a1a2e; color: #e0e0e0; }
        h1 { color: #00ff88; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #333; padding: 8px; text-align: left; }
        th { background: #16213e; }
        .success { color: #00ff88; }
        .failed { color: #ff4444; }
        .running { color: #ffaa00; }
        .btn { padding: 8px 16px; margin: 4px; border: none; border-radius: 4px; cursor: pointer; }
        .btn-trigger { background: #00ff88; color: #1a1a2e; }
        .btn-status { background: #16213e; color: #e0e0e0; border: 1px solid #333; }
      </style></head><body>
        <h1>Tunefy Sync Administration</h1>
        <p>Server time: ${new Date().toISOString()}</p>
        <button class="btn btn-status" onclick="location.reload()">Refresh Status</button>
        <button class="btn btn-trigger" onclick="trigger('jamendo')">Trigger Jamendo</button>
        <button class="btn btn-trigger" onclick="trigger('audius')">Trigger Audius</button>
        <button class="btn btn-trigger" onclick="trigger('youtube')">Trigger YouTube</button>
        <button class="btn btn-trigger" onclick="trigger('itunes')">Trigger iTunes</button>
        <button class="btn btn-trigger" onclick="trigger('orchestrator')">Trigger Full Sync</button>
        <h2>Last 10 Sync Runs</h2>
        <table><thead><tr><th>Source</th><th>Started</th><th>Finished</th><th>Status</th><th>Albums</th><th>Tracks</th><th>Playlists</th><th>Error</th></tr></thead>
        <tbody>${(lastSync || []).map((s: any) => `<tr>
          <td>${s.source}</td>
          <td>${s.started_at}</td>
          <td>${s.finished_at || "-"}</td>
          <td class="${s.status}">${s.status}</td>
          <td>${s.albums_added || 0}</td>
          <td>${s.tracks_added || 0}</td>
          <td>${s.playlists_added || 0}</td>
          <td>${s.error_message || ""}</td>
        </tr>`).join("")}
        </tbody></table>
        <script>
        async function trigger(source) {
          const r = await fetch('/admin-dashboard?action=trigger&source=' + source, { method: 'POST' });
          const data = await r.json();
          alert(JSON.stringify(data, null, 2));
          location.reload();
        }
        </script>
      </body></html>`;

      return new Response(html, {
        status: 200,
        headers: { "Content-Type": "text/html" },
      });
    }

    return new Response(JSON.stringify({ error: "unknown action" }), { status: 400 });
  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});