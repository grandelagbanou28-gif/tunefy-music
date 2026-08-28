const express = require('express');
const router = express.Router();

const { CATALOG } = require('./catalog');
const { getTagTopTracks, getGeoTopTracks } = require('../lib/lastfm_catalog');

/**
 * @swagger
 * /api/charts:
 *   get:
 *     summary: Get charts (global or by country)
 *     parameters:
 *       - in: query
 *         name: country
 *         schema:
 *           type: string
 *         description: Country code
 *     responses:
 *       200:
 *         description: Charts data
 *       500:
 *         description: Charts data unavailable
 */
router.get('/charts', async (req, res) => {
  try {
    const { country } = req.query;
    const ytmusic = req.app.locals.ytmusic;
    
    const data = await ytmusic.getCharts(country);
    res.json(data);
  } catch (error) {
    console.error('Charts error:', error);
    const errorMsg = error.message || 'Charts service temporarily unavailable';
    res.status(500).json({
      error: `Charts data unavailable: ${errorMsg}`,
      message: 'YouTube Music charts are currently not accessible. This may be due to regional restrictions or service limitations.',
      fallback: 'Try using the search endpoint instead: /api/search?q=trending&filter=songs'
    });
  }
});

/**
 * @swagger
 * /api/moods:
 *   get:
 *     summary: Get mood/genre categories
 *     responses:
 *       200:
 *         description: Mood categories
 *       500:
 *         description: Mood categories unavailable
 */
router.get('/moods', async (req, res) => {
  try {
    const ytmusic = req.app.locals.ytmusic;
    const data = await ytmusic.getMoodCategories();
    const real = data.filter(c => c.title && c.items && c.items.length);
    if (real.length) return res.json({ source: 'ytmusic', categories: real });
    // Fallback: the open source category catalog (Last.fm tags + geo + RSS).
    const fallback = CATALOG.map(({ id, type, tag, label, browseId, country }) => ({
      title: label, id, source: type,
      items: [],
      hint: tag || browseId || country || null,
      type,
    }));
    res.json({ source: 'catalog', categories: fallback });
  } catch (error) {
    console.error('Moods error:', error);
    const fallback = CATALOG.map(({ id, type, tag, label, browseId, country }) => ({
      title: label, id, source: type, items: [], hint: tag || browseId || country || null, type,
    }));
    res.json({ source: 'catalog', categories: fallback });
  }
});

function isHintedBrowseId(id) {
  return /^(FEmusic_|OLAK|RDAMPL|VL|RDCLAK|MPREb|UC)/.test(id || '');
}

/**
 * @swagger
 * /api/moods/{categoryId}:
 *   get:
 *     summary: Get playlists for a mood/genre category
 *     parameters:
 *       - in: path
 *         name: categoryId
 *         required: true
 *         schema:
 *           type: string
 *         description: Category ID
 *     responses:
 *       200:
 *         description: Mood playlists
 *       500:
 *         description: Mood playlists unavailable
 */
router.get('/moods/:categoryId', async (req, res) => {
  try {
    const { categoryId } = req.params;
    const ytmusic = req.app.locals.ytmusic;

    // Trying a real YouTube Music category first (its browseId starts with a
    // known prefix); catalog slugs (rap_fr, amapiano, …) go straight to the
    // open fallback without hitting the geo-gated innerTube endpoint.
    if (isHintedBrowseId(categoryId)) {
      const data = await ytmusic.getMoodPlaylists(categoryId);
      if (Array.isArray(data) && data.length) {
        return res.json({ source: 'ytmusic', items: data });
      }
    }

    // Fallback: resolve the category through the open catalog (Last.fm tag).
    const entry = CATALOG.find(c =>
      c.id === categoryId || c.tag === categoryId || (c.browseId && c.browseId === categoryId));
    if (entry && (entry.tag || entry.country)) {
      const items = entry.country
        ? await getGeoTopTracks(entry.country, 25)
        : await getTagTopTracks(entry.tag, 25);
      return res.json({ source: 'catalog', items, entry: { id: entry.id, label: entry.label } });
    }
    res.json({ source: 'catalog', items: [], entry: null });
  } catch (error) {
    console.error('Mood playlists error:', error);
    const entry = CATALOG.find(c => c.id === categoryId || c.tag === categoryId);
    if (entry && entry.tag) {
      try {
        const items = entry.country
          ? await getGeoTopTracks(entry.country, 25)
          : await getTagTopTracks(entry.tag, 25);
        return res.json({ source: 'catalog', items, entry: { id: entry.id, label: entry.label } });
      } catch (_) {}
    }
    res.status(500).json({
      error: `Mood playlists unavailable: ${error.message}`,
      message: `Mood playlists for category '${req.params.categoryId}' are currently not accessible.`,
      fallback: 'Try using the tags endpoint instead: /api/tags?tag=pop'
    });
  }
});

/**
 * @swagger
 * /api/watch_playlist:
 *   get:
 *     summary: Get watch playlist (radio/shuffle)
 *     parameters:
 *       - in: query
 *         name: videoId
 *         schema:
 *           type: string
 *         description: Video ID
 *       - in: query
 *         name: playlistId
 *         schema:
 *           type: string
 *         description: Playlist ID
 *       - in: query
 *         name: radio
 *         schema:
 *           type: boolean
 *           default: false
 *         description: Radio mode
 *       - in: query
 *         name: shuffle
 *         schema:
 *           type: boolean
 *           default: false
 *         description: Shuffle mode
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 25
 *         description: Maximum number of tracks
 *     responses:
 *       200:
 *         description: Watch playlist data
 *       400:
 *         description: Missing params
 */
router.get('/watch_playlist', async (req, res) => {
  try {
    const { videoId, playlistId, radio = false, shuffle = false, limit = 25 } = req.query;
    
    if (!videoId && !playlistId) {
      return res.status(400).json({ error: 'Provide either videoId or playlistId' });
    }

    const ytmusic = req.app.locals.ytmusic;
    const data = await ytmusic.getWatchPlaylist(
      videoId, 
      playlistId, 
      radio === 'true', 
      shuffle === 'true', 
      parseInt(limit)
    );
    
    res.json(data);
  } catch (error) {
    console.error('Watch playlist error:', error);
    res.status(500).json({ error: `Watch playlist unavailable: ${error.message}` });
  }
});

module.exports = router;
