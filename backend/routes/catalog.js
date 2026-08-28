const express = require('express');
const router = express.Router();

const { getTagTopTracks, getTagTopAlbums, getGeoTopTracks } = require('../lib/lastfm_catalog');
const { newReleases, decadeReleases } = require('../lib/musicbrainz_api');

// ─── Category catalog ─────────────────────────────────────────────────────
// Each spot in the app's "Moods & Genres" / "Curated" screens maps to a real
// open source data source: a Last.fm tag (genres), a YouTube Music mood shelf
// (ytmusic moods) or a storefront RSS. All metadata is resolved to playable
// YouTube items by the client through /api/search.
const CATALOG = [
  { id: 'amapiano', type: 'tag', tag: 'amapiano', label: 'Amapiano' },
  { id: 'new_release', type: 'newreleases', label: 'Nouveautés' },
  { id: 'pop', type: 'tag', tag: 'pop', label: 'Pop' },
  { id: 'hip_hop', type: 'tag', tag: 'hip-hop', label: 'Hip-Hop' },
  { id: 'rock', type: 'tag', tag: 'rock', label: 'Rock' },
  { id: 'latin', type: 'tag', tag: 'latin', label: 'Latin' },
  { id: 'mood', type: 'ytmood', browseId: 'FEmusic_moods_and_genres', label: 'Mood' },
  { id: 'decades', type: 'decades', label: 'Décades' },
  { id: 'country', type: 'tag', tag: 'country', label: 'Country' },
  { id: 'rnb', type: 'tag', tag: 'rnb', label: 'R&B' },
  { id: 'kpop', type: 'tag', tag: 'k-pop', label: 'K-Pop' },
  { id: 'india', type: 'geo', country: 'India', label: 'Inde' },
  { id: 'focus', type: 'tag', tag: 'focus', label: 'Focus' },
  { id: 'sleep', type: 'tag', tag: 'sleep', label: 'Sleep' },
  { id: 'party', type: 'tag', tag: 'party', label: 'Party' },
  { id: 'trending', type: 'trending', label: 'Tendances' },
  { id: 'soundtrack', type: 'tag', tag: 'soundtrack', label: 'Bande originale' },
  { id: 'afro_hits', type: 'tag', tag: 'afro', label: 'Afro Hits' },
  { id: 'chansons', type: 'geo', country: 'France', label: 'Chansons' },
  { id: 'rap_fr', type: 'tag', tag: 'french rap', label: 'Rap FR' },
  { id: 'afrobeats', type: 'tag', tag: 'afrobeats', label: 'Afrobeats' },
  { id: 'reggae', type: 'tag', tag: 'reggae', label: 'Reggae' },
  { id: 'jazz', type: 'tag', tag: 'jazz', label: 'Jazz' },
  { id: 'classical', type: 'tag', tag: 'classical', label: 'Classique' },
  { id: 'electronic', type: 'tag', tag: 'electronic', label: 'Électronique' },
  { id: 'drill', type: 'tag', tag: 'drill', label: 'Drill' },
  { id: 'soul', type: 'tag', tag: 'soul', label: 'Soul' },
  { id: 'chill', type: 'tag', tag: 'chill', label: 'Chill' },
  { id: 'metal', type: 'tag', tag: 'metal', label: 'Metal' },
  { id: 'blues', type: 'tag', tag: 'blues', label: 'Blues' },
  { id: 'folk_acoustic', type: 'tag', tag: 'folk', label: 'Folk & Acoustic' },
  { id: 'gospel', type: 'tag', tag: 'gospel', label: 'Gospel' },
  { id: 'funk_house', type: 'tag', tag: 'funk', label: 'Funk House' },
  { id: 'lo_fi', type: 'tag', tag: 'lofi', label: 'Lo-Fi Beats' },
  { id: 'rap', type: 'tag', tag: 'rap', label: 'Rap' },
  { id: 'rumba', type: 'tag', tag: 'rumba', label: 'Rumba' },
  { id: 'arab', type: 'tag', tag: 'arabic', label: 'Musique arabe' },
  { id: 'meditation', type: 'tag', tag: 'meditation', label: 'Méditation' },
  { id: 'caribbean', type: 'tag', tag: 'reggaeton', label: 'Caribbean' },
  { id: 'desi', type: 'tag', tag: 'desi', label: 'Desi' },
  { id: 'romance', type: 'tag', tag: 'romantic', label: 'Romance' },
  { id: 'dancehall', type: 'tag', tag: 'dancehall', label: 'Dancehall' },
];

const TAG_ALIASES = {
  'rap fr': 'french rap',
  'rap-fr': 'french rap',
  'rapfrancais': 'french rap',
  'rap français': 'french rap',
  'hiphop': 'hip-hop',
  'hip hop': 'hip-hop',
  'rnb': 'rnb',
  'r&b': 'rnb',
  'soul': 'soul',
  'lofi': 'lo-fi',
  'lo-fi beats': 'lo-fi',
  'música árabe': 'arabic',
  'musique arabe': 'arabic',
  'raï': 'rai',
  'kpop': 'k-pop',
  'c-pop': 'c-pop',
  'ost': 'soundtrack',
  'soundtrack': 'soundtrack',
  'film score': 'soundtrack',
  'classique': 'classical',
  'électronique': 'electronic',
  'electro': 'electronic',
  'électro': 'electronic',
  'meditation': 'meditation',
  'méditation': 'meditation',
  'romance': 'romantic',
  'romantique': 'romantic',
  'amour': 'love',
  'party': 'party',
  'fête': 'party',
  'focus': 'focus',
  'concentration': 'focus',
  'sleep': 'sleep',
  'sommeil': 'sleep',
  'chill': 'chill',
  'jazz': 'jazz',
  'blues': 'blues',
  'metal': 'metal',
  'gospel': 'gospel',
  'funk': 'funk',
  'house': 'house',
  'reggae': 'reggae',
  'dancehall': 'dancehall',
  'reggaeton': 'reggaeton',
  'kizomba': 'kizomba',
  'afrobeats': 'afrobeats',
  'afrobeat': 'afrobeats',
  'amapiano': 'amapiano',
  'drill': 'drill',
  'rap': 'rap',
  'country': 'country',
  'latin': 'latin',
  'pop': 'pop',
  'rock': 'rock',
  'desi': 'desi',
  'bollywood': 'bollywood',
  'rumba': 'rumba',
  'afro': 'afro',
  'meditation': 'meditation',
  'decades': 'decades',
};

/**
 * @swagger
 * /api/categories:
 *   get:
 *     summary: List of curated categories with their open data source
 *     responses:
 *       200:
 *         description: Category list
 */
router.get('/categories', (req, res) => {
  res.json(CATALOG);
});

/**
 * @swagger
 * /api/tags:
 *   get:
 *     summary: Top tracks/albums for a music tag (Last.fm open API)
 *     parameters:
 *       - in: query
 *         name: tag
 *         required: true
 *         schema: { type: string }
 *       - in: query
 *         name: type
 *         schema: { type: string, enum: [tracks, albums], default: tracks }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *     responses:
 *       200:
 *         description: Track/album metadata (resolve via /api/search)
 */
router.get('/tags', async (req, res) => {
  try {
    const { tag, type = 'tracks', limit = 20 } = req.query;
    if (!tag) return res.status(400).json({ error: 'Missing required parameter: tag' });
    const effective = TAG_ALIASES[String(tag).toLowerCase().trim()] || tag;
    const items = type === 'albums'
      ? await getTagTopAlbums(effective, Number(limit))
      : await getTagTopTracks(effective, Number(limit));
    if (!items.length && effective !== tag) {
      // alias produced nothing → fall back to the raw tag
      const items2 = type === 'albums'
        ? await getTagTopAlbums(tag, Number(limit))
        : await getTagTopTracks(tag, Number(limit));
      return res.json({ tag, resolved: false, items: items2 });
    }
    res.json({ tag, resolved: effective, items });
  } catch (error) {
    console.error('Tags error:', error);
    res.status(500).json({ error: `Tags unavailable: ${error.message}` });
  }
});

/**
 * @swagger
 * /api/newreleases:
 *   get:
 *     summary: Recent album releases (MusicBrainz open data)
 *     parameters:
 *       - in: query
 *         name: days
 *         schema: { type: integer, default: 30 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 25 }
 *     responses:
 *       200:
 *         description: Recent releases
 */
router.get('/newreleases', async (req, res) => {
  try {
    const { days = 30, limit = 25 } = req.query;
    const items = await newReleases(Number(days), Number(limit));
    res.json({ days: Number(days), items });
  } catch (error) {
    console.error('New releases error:', error);
    res.status(500).json({ error: `New releases unavailable: ${error.message}` });
  }
});

/**
 * @swagger
 * /api/decades:
 *   get:
 *     summary: Albums released in a decade (MusicBrainz open data)
 *     parameters:
 *       - in: query
 *         name: year
 *         required: true
 *         schema: { type: integer }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 25 }
 *     responses:
 *       200:
 *         description: Decade albums
 */
router.get('/decades', async (req, res) => {
  try {
    const { year, limit = 25 } = req.query;
    if (!year) return res.status(400).json({ error: 'Missing required parameter: year' });
    const y = Number(year);
    try {
      const items = await decadeReleases(y, Number(limit));
      return res.json({ decade: y, items });
    } catch (err) {
      // MusicBrainz rate-limited/offline → same decade via Last.fm tag ("90s"…).
      const fallbackItems = await getTagTopAlbums(`${y}s`, Number(limit));
      return res.json({ decade: y, source: 'lastfm', items: fallbackItems });
    }
  } catch (error) {
    console.error('Decades error:', error);
    res.status(500).json({ error: `Decades unavailable: ${error.message}` });
  }
});

module.exports = { router, CATALOG, TAG_ALIASES };