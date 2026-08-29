import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/indian_content_filter.dart';

/// Apple iTunes Search API client — 100% free, no key, no rate-limit quota.
///
/// iTunes' catalog is excellent for FR / US / Afro content (the French store
/// dominates French-language music and the US store carries Afrobeats), so its
/// search relevance for those markets beats a generic YouTube search.
///
/// We use it as the *search & metadata* layer (find the right tracks) and keep
/// the existing ytify backend for full-audio streaming.
///
/// Docs: https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/
class ItunesApiService {
  static const String _base = 'https://itunes.apple.com';
  static const Duration _timeout = Duration(seconds: 12);

  final http.Client _client = http.Client();

  /// iTunes' Akamai edge rejects Dart's default `Dart/x (dart:io)` user-agent
  /// with HTTP 403 — sending a real browser UA makes requests work.
  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': '*/*',
  };

  void dispose() => _client.close();

  // ─── Search ───────────────────────────────────────────────────────────────

  /// Search songs on one store. `country` is the two-letter store code
  /// ('FR', 'US'...). Results are already relevance-ranked by iTunes.
  Future<List<MuzoItem>> searchSongs(
    String query, {
    int limit = 15,
    String country = 'US',
  }) async {
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'term': query,
      'media': 'music',
      'entity': 'song',
      'limit': '$limit',
      'country': country,
    });
    final results = await _results(uri);
    return filterIndianContent(
      results
          .map((e) => _songToMuzo(Map<String, dynamic>.from(e as Map)))
          .toList(),
      contextQuery: query,
    );
  }

  /// Search songs on the FR store then the US store and merge, so the section
  /// covers French AND American / Afro content in one go.
  Future<List<MuzoItem>> searchSongsFrUs(
    String query, {
    int limit = 8,
  }) async {
    final futures = [
      searchSongs(query, limit: limit, country: 'FR'),
      searchSongs(query, limit: limit, country: 'US'),
    ];
    final batches = await Future.wait(futures);
    return dedupeMuzoSongs([...batches[0], ...batches[1]]);
  }

  /// Search albums.
  Future<List<MuzoItem>> searchAlbums(String query, {int limit = 20}) async {
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'term': query,
      'media': 'music',
      'entity': 'album',
      'limit': '$limit',
    });
    final results = await _results(uri);
    return filterIndianContent(
      results
          .map((e) => _albumToMuzo(Map<String, dynamic>.from(e as Map)))
          .toList(),
      contextQuery: query,
    );
  }

  /// Search artists.
  Future<List<MuzoItem>> searchArtists(String query, {int limit = 12}) async {
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'term': query,
      'media': 'music',
      'entity': 'musicArtist',
      'limit': '$limit',
    });
    final results = await _results(uri);
    return results
        .map((e) => _artistToMuzo(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Search full podcast EPISODES (comedy specials, news, interviews, shows).
  /// Episodes carry a direct `episodeUrl` (MP3 / M4A) which the player streams
  /// natively through the `user_track` path — no YouTube involved. Items
  /// without an episode URL are dropped (they would be silent cards).
  /// At most [maxPerShow] episodes of the same show are kept so one prolific
  /// podcast cannot flood an entire section.
  Future<List<MuzoItem>> searchPodcastEpisodes(
    String query, {
    int limit = 12,
    int maxPerShow = 3,
    String country = 'US',
  }) async {
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'term': query,
      'media': 'podcast',
      'entity': 'podcastEpisode',
      'limit': '$limit',
      'country': country,
    });
    final results = await _results(uri);
    final seenShows = <String, int>{};
    final items = <MuzoItem>[];
    for (final e in results) {
      final item = _episodeToMuzo(Map<String, dynamic>.from(e as Map));
      if (item.audioUrl == null || item.audioUrl!.isEmpty) continue;
      final show = (item.channelName ?? '').toLowerCase();
      final count = seenShows[show] ?? 0;
      if (show.isNotEmpty && count >= maxPerShow) continue;
      if (show.isNotEmpty) seenShows[show] = count + 1;
      items.add(item);
    }
    return items;
  }

  /// Episodes from the FR store then the US store merged, so French-language
  /// shows (comédie stand-up, actu française) and US content coexist.
  Future<List<MuzoItem>> searchPodcastEpisodesFrUs(
    String query, {
    int limit = 10,
    int maxPerShow = 3,
  }) async {
    final futures = [
      searchPodcastEpisodes(query,
          limit: limit, maxPerShow: maxPerShow, country: 'FR'),
      searchPodcastEpisodes(query,
          limit: limit, maxPerShow: maxPerShow, country: 'US'),
    ];
    final batches = await Future.wait(futures);
    return dedupeMuzoSongs([...batches[0], ...batches[1]]);
  }

  // ─── Lookup (album details with ALL tracks) ──────────────────────────────

  /// Full album with ALL its tracks via the lookup endpoint.
  Future<ItunesAlbum?> getAlbum(int albumId) async {
    final uri = Uri.parse('$_base/lookup').replace(queryParameters: {
      'id': '$albumId',
      'entity': 'song',
    });
    try {
      final resp = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final raw = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (raw['results'] as List?) ?? [];
      final albumRaw = list.cast<Map>().where(
        (e) => (e['wrapperType'] as String?) == 'collection',
      ).toList();
      if (albumRaw.isEmpty) return null;
      final albumMap = Map<String, dynamic>.from(albumRaw.first);
      final tracks = list
          .cast<Map>()
          .where((e) => (e['wrapperType'] as String?) == 'track')
          .map((e) => _songToMuzo(Map<String, dynamic>.from(e)))
          .toList();
      return ItunesAlbum(
        id: albumId,
        title: albumMap['collectionName'] as String? ?? '',
        artist: albumMap['artistName'] as String? ?? '',
        coverUrl: _hiResArtwork(albumMap['artworkUrl100'] as String? ?? ''),
        releaseDate: albumMap['releaseDate'] as String?,
        tracks: tracks,
      );
    } catch (e) {
      debugPrint('ITUNES lookup fail $albumId :: $e');
      return null;
    }
  }

  // ─── helpers ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> _results(Uri uri) async {
    try {
      final resp = await _client
          .get(uri, headers: _headers)
          .timeout(_timeout);
      if (resp.statusCode != 200) {
        debugPrint('ITUNES HTTP ${resp.statusCode} $uri');
        return const [];
      }
      final raw = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (raw['results'] as List?) ?? const [];
      debugPrint('ITUNES OK ${list.length} $uri');
      return list;
    } catch (e) {
      debugPrint('ITUNES FAIL $uri :: $e');
      return const [];
    }
  }

  /// Bump iTunes' default 100x100 artwork to 600x600 when possible.
  static String _hiResArtwork(String url) {
    if (url.isEmpty) return '';
    return url.replaceAll('100x100bb', '600x600bb');
  }

  MuzoItem _songToMuzo(Map<String, dynamic> r) {
    final artist = r['artistName'] as String?;
    final durMs = (r['trackTimeMillis'] as num?)?.toInt() ?? 0;
    final dur = durMs > 0 ? durMs ~/ 1000 : 0;
    final explicitness = (r['trackExplicitness'] as String?) ?? '';
    final albumName = r['collectionName'] as String?;
    final cover = _hiResArtwork(r['artworkUrl100'] as String? ?? '');
    // iTunes song previews are 30s clips — never streamable as real songs.
    // The item keeps its catalog metadata (title/art/artist) so it can be
    // used to seed searches, but it carries NO audioUrl and a non-YouTube id,
    // so playability filters drop it from every playable list. Real music
    // comes from muzoapi (YouTube); iTunes is only used for podcast EPISODES.
    return MuzoItem(
      title: (r['trackName'] as String?) ?? '',
      thumbnails: cover.isNotEmpty
          ? [MuzoThumbnail(url: cover, width: 600, height: 600)]
          : const [],
      resultType: 'song',
      isExplicit: explicitness == 'explicit',
      videoId: 'it_${r['trackId']}',
      durationSeconds: dur,
      duration: dur > 0
          ? '${(dur ~/ 60).toString().padLeft(1, '0')}:${(dur % 60).toString().padLeft(2, '0')}'
          : null,
      artists: artist != null ? [MuzoArtist(name: artist, id: null)] : null,
      channelName: artist,
      album: albumName != null ? MuzoAlbum(name: albumName, id: '') : null,
      audioUrl: null,
      source: 'itunes',
      sourceId: (r['trackId'] as num?)?.toString(),
      sourceUrl: (r['previewUrl'] as String?) ?? '',
      fetchedAt: DateTime.now(),
    );
  }

  /// Podcast episode → playable MuzoItem (full-length MP3 via episodeUrl).
  MuzoItem _episodeToMuzo(Map<String, dynamic> r) {
    final show = (r['collectionName'] as String?) ??
        (r['artistName'] as String?) ??
        '';
    final artist = r['artistName'] as String?;
    final durMs = (r['trackTimeMillis'] as num?)?.toInt() ?? 0;
    final dur = durMs > 0 ? durMs ~/ 1000 : 0;
    final release = DateTime.tryParse((r['releaseDate'] as String?) ?? '');
    // Podcast episodes often expose artworkUrl600/160/60 but NOT
    // artworkUrl100 (iOS17+ API shape) — walk the size chain in order of
    // preference so episodes always get their show artwork.
    final cover = (r['artworkUrl600'] as String? ??
        r['artworkUrl100'] as String? ??
        r['artworkUrl160'] as String? ??
        r['artworkUrl60'] as String? ??
        '');
    // Bump any size to 600x600 (iTunes serves up to the largest available)
    // unless the cover is already the 600 variant.
    final coverHi = cover.contains('600x600')
        ? cover
        : cover.replaceFirst(RegExp(r'\d+x\d+bb'), '600x600bb');
    final coverSize = cover.contains('600x600')
        ? 600
        : cover.contains('160x160')
            ? 160
            : cover.contains('60x60')
                ? 60
                : 100;
    final episodeUrl = r['episodeUrl'] as String? ?? '';
    return MuzoItem(
      title: (r['trackName'] as String?) ?? '',
      thumbnails: cover.isNotEmpty
          ? [
              MuzoThumbnail(url: cover, width: coverSize, height: coverSize),
              if (coverHi.isNotEmpty && coverHi != cover)
                MuzoThumbnail(url: coverHi, width: 600, height: 600),
            ]
          : const [],
      resultType: 'user_track',
      isExplicit: false,
      // 'it_' prefix marks a non-YouTube id for the playability filter.
      videoId: 'it_pod_${r['trackId'] ?? ''}',
      durationSeconds: dur,
      duration: dur > 0
          ? '${dur ~/ 60}:${(dur % 60).toString().padLeft(2, '0')}'
          : null,
      artists: [MuzoArtist(name: show.isNotEmpty ? show : (artist ?? ''))],
      channelName: show.isNotEmpty ? show : artist,
      album: show.isNotEmpty ? MuzoAlbum(name: show, id: '') : null,
      releaseDate: release,
      audioUrl: episodeUrl.isEmpty ? null : episodeUrl,
      source: 'itunes podcast',
      sourceId: (r['trackId'] as num?)?.toString(),
      sourceUrl: episodeUrl.isEmpty ? null : episodeUrl,
      fetchedAt: DateTime.now(),
    );
  }

  MuzoItem _albumToMuzo(Map<String, dynamic> r) {
    final artist = r['artistName'] as String?;
    final cover = _hiResArtwork(r['artworkUrl100'] as String? ?? '');
    return MuzoItem(
      title: (r['collectionName'] as String?) ?? '',
      thumbnails: cover.isNotEmpty
          ? [MuzoThumbnail(url: cover, width: 600, height: 600)]
          : const [],
      resultType: 'album',
      isExplicit: false,
      videoId: 'it_album_${r['collectionId']}',
      artists: artist != null ? [MuzoArtist(name: artist, id: null)] : null,
      channelName: artist,
      source: 'itunes',
      sourceId: (r['collectionId'] as num?)?.toString(),
      fetchedAt: DateTime.now(),
    );
  }

  MuzoItem _artistToMuzo(Map<String, dynamic> r) {
    final name = r['artistName'] as String? ?? '';
    return MuzoItem(
      title: name,
      thumbnails: const [],
      resultType: 'artist',
      isExplicit: false,
      videoId: 'it_artist_${r['artistId']}',
      artists: name.isNotEmpty ? [MuzoArtist(name: name, id: null)] : null,
      channelName: name,
      source: 'itunes',
      sourceId: (r['artistId'] as num?)?.toString(),
      fetchedAt: DateTime.now(),
    );
  }
}

/// Full iTunes album with track list.
class ItunesAlbum {
  final int id;
  final String title;
  final String artist;
  final String coverUrl;
  final String? releaseDate;
  final List<MuzoItem> tracks;

  const ItunesAlbum({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    this.releaseDate,
    required this.tracks,
  });
}
