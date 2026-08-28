const axios = require('axios');

const MB_BASE = 'https://musicbrainz.org/ws/2/';
const UA = 'muzo-backend-fork/1.0 ( https://github.com/muzo-backend ; contact open source )';

async function mbGet(path, params) {
  const { data } = await axios.get(MB_BASE + path, {
    params: { fmt: 'json', ...params },
    headers: { 'User-Agent': UA },
    timeout: 15000,
  });
  return data;
}

function firstArtist(credit) {
  const c = (credit || [])[0];
  return c?.name || c?.artist?.name || '';
}

/**
 * Recent releases (albums) by earliest release date range.
 * Used for "New Releases" and "Decades" shelves, both free & open data.
 */
async function browseReleases({ dateFrom, dateTo, limit = 25, country = null }) {
  const parts = [];
  if (dateFrom && dateTo) parts.push(`date:[${dateFrom} TO ${dateTo}]`);
  if (country) parts.push(`country:${country}`);
  if (parts.length === 0) parts.push('*');
  const query = parts.join(' AND ');
  const data = await mbGet('release', {
    query,
    limit: Math.min(limit, 100),
  });
  return (data?.releases || [])
    .map((r, i) => ({
      title: r.title,
      artist: firstArtist(r['artist-credit']),
      date: r['release-date'] || r.date || '',
      country: r.country || '',
      rank: i + 1,
      source: 'musicbrainz',
    }))
    .filter(r => r.title && r.artist)
    .sort((a, b) => (b.date || '').localeCompare(a.date || ''));
}

/** New releases from the last N days (default 30). */
async function newReleases(days = 30, limit = 25) {
  const to = new Date();
  const from = new Date(to.getTime() - days * 86400000);
  const f = (d) => d.toISOString().slice(0, 10);
  return browseReleases({ dateFrom: f(from), dateTo: f(to), limit });
}

/** Everything released inside a decade (1990 → 1990-01-01…1999-12-31). */
async function decadeReleases(year, limit = 25) {
  const from = `${year}-01-01`;
  const to = `${year + 9}-12-31`;
  return browseReleases({ dateFrom: from, dateTo: to, limit });
}

module.exports = { newReleases, decadeReleases, browseReleases };