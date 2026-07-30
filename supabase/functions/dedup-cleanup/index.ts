import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const start = Date.now();
  const log: Record<string, any> = {
    source: "dedup-cleanup",
    started_at: new Date().toISOString(),
    status: "running",
    albums_deduped: 0,
    tracks_deduped: 0,
    playlists_deduped: 0,
    expired_removed: 0,
  };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_KEY")!;

    await dedupAlbums(supabaseUrl, supabaseKey, log);
    await dedupTracks(supabaseUrl, supabaseKey, log);
    await dedupPlaylists(supabaseUrl, supabaseKey, log);
    await cleanupExpired(supabaseUrl, supabaseKey, log);

    log.status = "success";
  } catch (e: any) {
    log.status = "failed";
    log.error_message = e.message;
  }

  log.finished_at = new Date().toISOString();
  log.duration_ms = Date.now() - start;

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
      body: JSON.stringify(log),
    }).catch(() => {});
  } catch (_) {}

  return new Response(JSON.stringify(log), { status: 200 });
});

async function dedupAlbums(
  supabaseUrl: string,
  supabaseKey: string,
  log: Record<string, any>
) {
  const { data: albums } = await fetch(
    `${supabaseUrl}/rest/v1/albums?select=id,source,source_id&order=source,source_id`,
    {
      headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
    }
  ).then((r) => r.json()).catch(() => null);

  if (!albums) return;

  const seen = new Map<string, string>();
  for (const album of albums) {
    const key = `${album.source}|${album.source_id}`;
    if (seen.has(key)) {
      await fetch(`${supabaseUrl}/rest/v1/albums?id=eq.${album.id}`, {
        method: "DELETE",
        headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
      }).catch(() => {});
      log.albums_deduped++;
    } else {
      seen.set(key, album.id);
    }
  }
}

async function dedupTracks(
  supabaseUrl: string,
  supabaseKey: string,
  log: Record<string, any>
) {
  const { data: tracks } = await fetch(
    `${supabaseUrl}/rest/v1/tracks?select=id,source,source_id&order=source,source_id`,
    {
      headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
    }
  ).then((r) => r.json()).catch(() => null);

  if (!tracks) return;

  const seen = new Map<string, string>();
  for (const track of tracks) {
    const key = `${track.source}|${track.source_id}`;
    if (seen.has(key)) {
      await fetch(`${supabaseUrl}/rest/v1/tracks?id=eq.${track.id}`, {
        method: "DELETE",
        headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
      }).catch(() => {});
      log.tracks_deduped++;
    } else {
      seen.set(key, track.id);
    }
  }
}

async function dedupPlaylists(
  supabaseUrl: string,
  supabaseKey: string,
  log: Record<string, any>
) {
  const { data: playlists } = await fetch(
    `${supabaseUrl}/rest/v1/playlists?select=id,source,source_id&order=source,source_id`,
    {
      headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
    }
  ).then((r) => r.json()).catch(() => null);

  if (!playlists) return;

  const seen = new Map<string, string>();
  for (const pl of playlists) {
    const key = `${pl.source}|${pl.source_id}`;
    if (seen.has(key)) {
      await fetch(`${supabaseUrl}/rest/v1/playlists?id=eq.${pl.id}`, {
        method: "DELETE",
        headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
      }).catch(() => {});
      log.playlists_deduped++;
    } else {
      seen.set(key, pl.id);
    }
  }
}

async function cleanupExpired(
  supabaseUrl: string,
  supabaseKey: string,
  log: Record<string, any>
) {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

  await fetch(
    `${supabaseUrl}/rest/v1/sync_logs?started_at=lt.${thirtyDaysAgo}`,
    {
      method: "DELETE",
      headers: {
        apikey: supabaseKey,
        Authorization: `Bearer ${supabaseKey}`,
      },
    }
  ).catch(() => {});
}