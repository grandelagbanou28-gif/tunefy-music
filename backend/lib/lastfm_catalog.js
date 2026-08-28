const axios = require('axios');

// Public Last.fm key already shipped in the upstream repo.
const LASTFM_API_KEY = process.env.LASTFM_API_KEY || '0867bcb6f36c879398969db682a7b69b';

const LASTFM_BASE = 'https://ws.audioscrobbler.com/2.0/';

function lfParams(method, params) {
  return {
    method,
    api_key: LASTFM_API_KEY,
    format: 'json',
    ...params,
  };
}

async function lfGet(params) {
  const { data } = await axios.get(LASTFM_BASE, { params: lfParams(null, params), timeout: 12000 });
  return data;
}

/**
 * Top tracks for a music tag (afrobeats, k-pop, drill, soundtrack, 90s, …).
 * Metadata only — no videoId: consumers resolve titles via /api/search.
 */
async function getTagTopTracks(tag, limit = 20) {
  const data = await lfGet({ method: 'tag.gettoptracks', tag, limit: Math.min(limit, 100) });
  const list = data?.tracks?.track || [];
  return list.map((t, i) => ({
    title: t.name,
    artist: t?.artist?.name || '',
    rank: i + 1,
    playcount: t.playcount,
    listeners: t.listeners,
    // 0=small 1=medium 2=large 3=extralarge
    thumbnail: t?.image?.[3]?.['#text'] || t?.image?.[2]?.['#text'] || '',
    source: 'lastfm',
    tag,
  })).filter(t => t.title && t.artist);
}

/**
 * Top albums for a music tag.
 */
async function getTagTopAlbums(tag, limit = 20) {
  const data = await lfGet({ method: 'tag.gettopalbums', tag, limit: Math.min(limit, 100) });
  const list = data?.albums?.album || [];
  return list.map((a, i) => ({
    title: a.name,
    artist: a?.artist?.name || '',
    rank: i + 1,
    playcount: a.playcount,
    thumbnail: a?.image?.[3]?.['#text'] || a?.image?.[2]?.['#text'] || '',
    source: 'lastfm',
    tag,
  })).filter(a => a.title && a.artist);
}

/**
 * Top tracks for a whole country (geo charts). country = Last.fm country name
 * ("France", "India", "United States", …).
 */
async function getGeoTopTracks(country, limit = 25) {
  const data = await lfGet({ method: 'geo.gettoptracks', country, limit: Math.min(limit, 100) });
  const list = data?.tracks?.track || [];
  return list.map((t, i) => ({
    title: t.name,
    artist: t?.artist?.name || '',
    rank: i + 1,
    thumbnail: t?.image?.[3]?.['#text'] || '',
    source: 'lastfm',
    country,
  })).filter(t => t.title && t.artist);
}

module.exports = { getTagTopTracks, getTagTopAlbums, getGeoTopTracks, LASTFM_API_KEY };