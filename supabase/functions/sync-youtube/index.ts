import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const YT_API_KEY = Deno.env.get("YOUTUBE_API_KEY") || "";
const YT_BASE = "https://www.googleapis.com/youtube/v3";

serve(async (req) => {
  const start = Date.now();
  const log: Record<string, any> = {
    source: "youtube",
    started_at: new Date().toISOString(),
    status: "running",
    albums_found: 0,
    albums_added: 0,
    albums_updated: 0,
    tracks_found: 0,
    tracks_added: 0,
    tracks_updated: 0,
    playlists_found: 0,
    playlists_added: 0,
    playlists_updated: 0,
    artists_found: 0,
    artists_added: 0,
  };

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_KEY")!;

    const { data: config } = await fetch(
      `${supabaseUrl}/rest/v1/sync_config?source=youtube&limit=1`,
      {
        headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
      }
    ).then((r) => r.json()).catch(() => null);

    if (!config?.enabled) {
      log.status = "skipped";
      await finish(supabaseUrl, supabaseKey, log, start);
      return new Response(JSON.stringify(log), { status: 200 });
    }

    const limit = config.batch_size || 50;

    await syncYouTubePlaylists(supabaseUrl, supabaseKey, limit, log);
    await syncYouTubeSongs(supabaseUrl, supabaseKey, limit, log);

    log.status = "success";
  } catch (e: any) {
    log.status = "failed";
    log.error_message = e.message;
  }

  log.finished_at = new Date().toISOString();
  log.duration_ms = Date.now() - start;
  await finish(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_KEY")!, log, start);
  return new Response(JSON.stringify(log), { status: 200 });
});

async function syncYouTubePlaylists(
  supabaseUrl: string,
  supabaseKey: string,
  limit: number,
  log: Record<string, any>
) {
  const genres = ["rap fr", "rap us", "hip hop", "afrobeat", "pop", "rnb", "gospel", "reggae", "dancehall", "ampiano"];

  for (const genre of genres) {
    let nextPageToken: string | undefined;
    let hasMore = true;

    while (hasMore) {
      try {
        const params = new URLSearchParams({
          part: "snippet,contentDetails",
          q: genre,
          type: "playlist",
          maxResults: String(limit),
          key: YT_API_KEY,
        });
        if (nextPageToken) params.set("pageToken", nextPageToken);

        const res = await fetch(`${YT_BASE}/search?${params}`).then((r) => r.json()).catch(() => null);
        const items = res?.items || [];

        if (items.length === 0) {
          hasMore = false;
          break;
        }

        log.playlists_found += items.length;

        for (const item of items) {
          const snippet = item.snippet || {};
          const playlistId = item.id?.playlistId;
          if (!playlistId) continue;

          const playlistData: any = {
            source: "youtube",
            source_id: playlistId,
            title: snippet.title || "",
            description: snippet.description || null,
            cover_url: snippet.thumbnails?.high?.url || snippet.thumbnails?.default?.url || null,
            owner_name: snippet.channelTitle || null,
            track_count: 0,
            updated_at: new Date().toISOString(),
          };

          const { data: existing } = await fetch(
            `${supabaseUrl}/rest/v1/playlists?source=youtube&source_id=${encodeURIComponent(playlistId)}&limit=1`,
            {
              headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
            }
          ).then((r) => r.json()).catch(() => null);

          if (existing && existing.length > 0) {
            await fetch(`${supabaseUrl}/rest/v1/playlists?id=eq.${existing[0].id}`, {
              method: "PATCH",
              headers: { "Content-Type": "application/json", apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
              body: JSON.stringify(playlistData),
            }).catch(() => {});
            log.playlists_updated++;
          } else {
            playlistData.created_at = new Date().toISOString();
            const { data: newPlaylist } = await fetch(
              `${supabaseUrl}/rest/v1/playlists`,
              {
                method: "POST",
                headers: { "Content-Type": "application/json", apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
                body: JSON.stringify(playlistData),
              }
            ).then((r) => r.json()).catch(() => null);

            if (newPlaylist) {
              log.playlists_added++;
              await fetchYouTubePlaylistTracks(supabaseUrl, supabaseKey, newPlaylist.id, playlistId, log);
            }
          }
        }

        nextPageToken = res?.nextPageToken;
        if (!nextPageToken) hasMore = false;
        await sleep(100);
      } catch (e: any) {
        log.error_message = `YouTube playlist error: ${e.message}`;
        hasMore = false;
      }
    }
  }
}

async function fetchYouTubePlaylistTracks(
  supabaseUrl: string,
  supabaseKey: string,
  playlistDbId: string,
  youtubePlaylistId: string,
  log: Record<string, any>
) {
  let nextPageToken: string | undefined;
  let position = 0;
  let hasMore = true;

  while (hasMore) {
    try {
      const params = new URLSearchParams({
        part: "snippet",
        playlistId: youtubePlaylistId,
        maxResults: "50",
        key: YT_API_KEY,
      });
      if (nextPageToken) params.set("pageToken", nextPageToken);

      const res = await fetch(`${YT_BASE}/playlistItems?${params}`).then((r) => r.json()).catch(() => null);
      const items = res?.items || [];

      if (items.length === 0) {
        hasMore = false;
        break;
      }

      log.tracks_found += items.length;

      for (const item of items) {
        const snippet = item.snippet || {};
        const videoId = snippet.resourceId?.videoId;
        if (!videoId) continue;

        const trackData: any = {
          source: "youtube",
          source_id: videoId,
          title: snippet.title || "",
          audio_url: null,
          preview_url: null,
          duration: 0,
          track_number: position + 1,
          cover_url: snippet.thumbnails?.high?.url || null,
          release_date: null,
          genre: null,
          updated_at: new Date().toISOString(),
        };

        const { data: existing } = await fetch(
          `${supabaseUrl}/rest/v1/tracks?source=youtube&source_id=${encodeURIComponent(videoId)}&limit=1`,
          {
            headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
          }
        ).then((r) => r.json()).catch(() => null);

        let trackDbId: string | null = null;

        if (existing && existing.length > 0) {
          await fetch(`${supabaseUrl}/rest/v1/tracks?id=eq.${existing[0].id}`, {
            method: "PATCH",
            headers: { "Content-Type": "application/json", apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
            body: JSON.stringify(trackData),
          }).catch(() => {});
          log.tracks_updated++;
          trackDbId = existing[0].id;
        } else {
          trackData.created_at = new Date().toISOString();
          const { data: newTrack } = await fetch(
            `${supabaseUrl}/rest/v1/tracks`,
            {
              method: "POST",
              headers: { "Content-Type": "application/json", apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
              body: JSON.stringify(trackData),
            }
          ).then((r) => r.json()).catch(() => null);

          if (newTrack) {
            log.tracks_added++;
            trackDbId = newTrack.id;
          }
        }

        if (trackDbId) {
          await fetch(`${supabaseUrl}/rest/v1/playlist_tracks`, {
            method: "INSERT",
            headers: { "Content-Type": "application/json", apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
            body: JSON.stringify({
              playlist_id: playlistDbId,
              track_id: trackDbId,
              position,
              added_at: new Date().toISOString(),
            }),
          }).catch(() => {});
        }

        position++;
      }

      nextPageToken = res?.nextPageToken;
      if (!nextPageToken) hasMore = false;
      await sleep(100);
    } catch (e: any) {
      log.error_message = `YouTube playlist tracks error: ${e.message}`;
      hasMore = false;
    }
  }
}

async function syncYouTubeSongs(
  supabaseUrl: string,
  supabaseKey: string,
  limit: number,
  log: Record<string, any>
) {
  const genres = ["rap fr 2026", "rap us 2026", "hip hop 2026", "afrobeat 2026", "pop 2026"];
  let totalSongs = 0;

  for (const genre of genres) {
    let nextPageToken: string | undefined;
    let hasMore = true;

    while (hasMore) {
      try {
        const params = new URLSearchParams({
          part: "snippet",
          q: genre,
          type: "video",
          maxResults: String(limit),
          order: "date",
          key: YT_API_KEY,
        });
        if (nextPageToken) params.set("pageToken", nextPageToken);

        const res = await fetch(`${YT_BASE}/search?${params}`).then((r) => r.json()).catch(() => null);
        const items = res?.items || [];

        if (items.length === 0) {
          hasMore = false;
          break;
        }

        totalSongs += items.length;
        log.tracks_found += items.length;

        for (const item of items) {
          const snippet = item.snippet || {};
          const videoId = item.id?.videoId;
          if (!videoId) continue;

          const trackData: any = {
            source: "youtube",
            source_id: videoId,
            title: snippet.title || "",
            audio_url: null,
            preview_url: null,
            duration: 0,
            track_number: null,
            cover_url: snippet.thumbnails?.high?.url || null,
            release_date: null,
            genre: genre.includes("rap fr") ? "rap fr" : genre.includes("rap us") ? "rap us" : genre.includes("hip hop") ? "hip hop" : genre.includes("afrobeat") ? "afrobeat" : genre,
            updated_at: new Date().toISOString(),
          };

          const { data: existing } = await fetch(
            `${supabaseUrl}/rest/v1/tracks?source=youtube&source_id=${encodeURIComponent(videoId)}&limit=1`,
            {
              headers: { apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
            }
          ).then((r) => r.json()).catch(() => null);

          if (existing && existing.length > 0) {
            await fetch(`${supabaseUrl}/rest/v1/tracks?id=eq.${existing[0].id}`, {
              method: "PATCH",
              headers: { "Content-Type": "application/json", apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
              body: JSON.stringify(trackData),
            }).catch(() => {});
            log.tracks_updated++;
          } else {
            trackData.created_at = new Date().toISOString();
            const { data: newTrack } = await fetch(
              `${supabaseUrl}/rest/v1/tracks`,
              {
                method: "POST",
                headers: { "Content-Type": "application/json", apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
                body: JSON.stringify(trackData),
              }
            ).then((r) => r.json()).catch(() => null);

            if (newTrack) log.tracks_added++;
          }
        }

        nextPageToken = res?.nextPageToken;
        if (!nextPageToken) hasMore = false;
        await sleep(100);
      } catch (e: any) {
        log.error_message = `YouTube songs error: ${e.message}`;
        hasMore = false;
      }
    }
  }
}

async function finish(
  supabaseUrl: string,
  supabaseKey: string,
  log: Record<string, any>,
  start: number
) {
  try {
    await fetch(`${supabaseUrl}/rest/v1/sync_logs`, {
      method: "POST",
      headers: { "Content-Type": "application/json", apikey: supabaseKey, Authorization: `Bearer ${supabaseKey}` },
      body: JSON.stringify(log),
    }).catch(() => {});
  } catch (_) {}
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}