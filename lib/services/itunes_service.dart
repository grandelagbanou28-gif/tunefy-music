import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tunefy/models/home_track.dart';

class ItunesService {
  static const _base = 'https://itunes.apple.com';
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    responseType: ResponseType.plain,
    headers: {'User-Agent': 'Tunefy/1.0'},
  ));

  static final Map<String, List<HomeTrack>> _artistTracksCache = {};
  static final Map<String, List<HomeAlbum>> _artistAlbumsCache = {};
  static final Map<String, List<HomeTrack>> _albumTracksCache = {};
  static final Map<String, List<Map<String, String>>> _artistPlaylistsCache = {};

  static String _fmtDuration(int millis) {
    final s = millis ~/ 1000;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  static String _artwork(String url) => url.replaceAll('100x100', '600x600');

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static Map<String, dynamic>? _safeMap(dynamic v) => v is Map<String, dynamic> ? v : null;

  static HomeTrack _toTrack(dynamic t) {
    final img = t['artworkUrl100'] as String? ?? '';
    return HomeTrack(
      videoId: '${_toInt(t['trackId']) != 0 ? t['trackId'] : t['collectionId'] ?? 0}',
      title: t['trackName'] as String? ?? '',
      artist: t['artistName'] as String? ?? '',
      duration: _fmtDuration(_toInt(t['trackTimeMillis'])),
      imageUrl: img.isNotEmpty ? _artwork(img) : '',
    );
  }

  static List<dynamic> _extractResults(dynamic data) {
    if (data is String) {
      try { data = jsonDecode(data); } catch (_) {}
    }
    if (data is Map && data['results'] is List) {
      return data['results'] as List;
    }
    return [];
  }

  static List<dynamic> _extractFeed(dynamic data) {
    if (data is String) {
      try { data = jsonDecode(data); } catch (_) { return []; }
    }
    if (data is Map) {
      final feed = data['feed'];
      if (feed is Map && feed['entry'] is List) return feed['entry'] as List;
    }
    return [];
  }

  static Future<List<HomeTrack>> searchTracksByQuery(String query, {int limit = 50}) async {
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': query, 'media': 'music', 'entity': 'song', 'limit': limit,
      });
      return _extractResults(r.data).map((t) => _toTrack(t)).toList();
    } catch (e) {
      debugPrint('ItunesService: searchTracksByQuery error: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> searchTracks(String query) async {
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': query, 'media': 'music', 'entity': 'song', 'limit': 25,
      });
      return _extractResults(r.data).whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      debugPrint('ItunesService: searchTracks error: $e');
      return [];
    }
  }

  static Future<List<HomeTrack>> fetchChartTracks({int limit = 100}) async {
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': 'top hits 2026', 'media': 'music', 'entity': 'song', 'limit': limit,
      });
      return _extractResults(r.data).map((t) => _toTrack(t)).toList();
    } catch (e) {
      debugPrint('ItunesService: fetchChartTracks error: $e');
      return [];
    }
  }

  static Future<List<HomeTrack>> fetchPodcasts({int limit = 20}) async {
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': 'music podcast interview', 'media': 'podcast', 'entity': 'podcastEpisode', 'limit': limit,
      });
      return _extractResults(r.data).map((e) {
        final img = e['artworkUrl600'] as String? ?? e['artworkUrl100'] as String? ?? '';
        return HomeTrack(
          videoId: '${e['trackId'] ?? 0}',
          title: e['trackName'] as String? ?? '',
          artist: e['collectionName'] as String? ?? '',
          duration: e['trackTimeMillis'] != null ? _fmtDuration(_toInt(e['trackTimeMillis'])) : '',
          imageUrl: img,
        );
      }).toList();
    } catch (e) {
      debugPrint('ItunesService: fetchPodcasts error: $e');
      return [];
    }
  }

  static Future<List<HomeArtist>> fetchChartArtists({int limit = 25}) async {
    try {
      final terms = ['rap 2026', 'pop 2026', 'afrobeat 2026', 'rnb 2026', 'latin 2026', 'rock 2026'];
      final perTerm = ((limit * 3) / terms.length).ceil();
      final results = await Future.wait(terms.map((t) => _dio.get('$_base/search', queryParameters: {
        'term': t, 'media': 'music', 'entity': 'song', 'limit': perTerm,
      }).catchError((_) => null))).timeout(const Duration(seconds: 30));
      final seen = <String>{};
      final artists = <HomeArtist>[];
      for (final r in results) {
        if (r == null) continue;
        for (final a in _extractResults(r.data)) {
          final name = a['artistName'] as String? ?? '';
          if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
          final img = _artwork(a['artworkUrl100'] as String? ?? '');
          artists.add(HomeArtist(name: name, image: '', listeners: '', imageUrl: img));
          if (artists.length >= limit) break;
        }
        if (artists.length >= limit) break;
      }
      return artists;
    } catch (e) {
      debugPrint('ItunesService: fetchChartArtists error: $e');
      return [];
    }
  }

  static Future<String> fetchArtistImage(String artistName) async {
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': artistName, 'media': 'music', 'entity': 'song', 'limit': 1,
      });
      final results = _extractResults(r.data);
      if (results.isNotEmpty) {
        final img = results.first['artworkUrl100'] as String? ?? '';
        if (img.isNotEmpty) return _artwork(img);
      }
    } catch (_) {}
    return '';
  }

  static Future<List<HomeAlbum>> fetchChartAlbums({int limit = 25}) async {
    try {
      final terms = ['rap français album', 'afrobeat album', 'pop album', 'hip hop album', 'rnb album'];
      final perTerm = ((limit * 2) / terms.length).ceil();
      final results = await Future.wait(terms.map((t) => _dio.get('$_base/search', queryParameters: {
        'term': t, 'media': 'music', 'entity': 'album', 'limit': perTerm, 'country': 'us',
      }).catchError((_) => null))).timeout(const Duration(seconds: 30));
      final seen = <String>{};
      final albums = <HomeAlbum>[];
      for (final r in results) {
        if (r == null) continue;
        for (final a in _extractResults(r.data)) {
          final name = a['collectionName'] as String? ?? '';
          if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
          final img = _artwork(a['artworkUrl100'] as String? ?? '');
          final release = a['releaseDate'] as String? ?? '';
          albums.add(HomeAlbum(
            title: name, artist: a['artistName'] as String? ?? '',
            image: '', year: release.split('-').first, imageUrl: img,
            collectionId: a['collectionId'] as int?,
          ));
          if (albums.length >= limit) break;
        }
        if (albums.length >= limit) break;
      }
      return albums;
    } catch (e) {
      debugPrint('ItunesService: fetchChartAlbums error: $e');
      return [];
    }
  }

  static Future<List<HomeAlbum>> fetchAlbumsByGenre(String genre, {int limit = 20, DateTime? minDate, DateTime? maxDate}) async {
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': '$genre new album 2026', 'media': 'music', 'entity': 'album', 'limit': limit * 3, 'country': 'us',
      });
      var raw = _extractResults(r.data);
      if (minDate != null || maxDate != null) {
        raw = raw.where((a) {
          final releaseStr = a['releaseDate'] as String?;
          if (releaseStr == null || releaseStr.isEmpty) return false;
          final release = DateTime.tryParse(releaseStr);
          if (release == null) return false;
          if (minDate != null && release.isBefore(minDate)) return false;
          if (maxDate != null && release.isAfter(maxDate)) return false;
          return true;
        }).toList();
      }
      final albums = raw.map((a) {
        final img = _artwork(a['artworkUrl100'] as String? ?? '');
        final release = a['releaseDate'] as String? ?? '';
        return HomeAlbum(
          title: a['collectionName'] as String? ?? '',
          artist: a['artistName'] as String? ?? '',
          image: '', year: release.split('-').first, imageUrl: img,
          collectionId: a['collectionId'] as int?,
        );
      }).toList();
      albums.removeWhere((a) => a.title.isEmpty || a.artist.isEmpty);
      return albums.take(limit).toList();
    } catch (e) {
      debugPrint('ItunesService: fetchAlbumsByGenre error: $e');
      return [];
    }
  }

  static Future<List<HomeTrack>> fetchArtistTopTracks(String artistName) async {
    if (_artistTracksCache.containsKey(artistName)) return _artistTracksCache[artistName]!;
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': artistName, 'media': 'music', 'entity': 'song', 'limit': 50,
      });
      final seen = <String>{};
      final tracks = <HomeTrack>[];
      for (final t in _extractResults(r.data)) {
        final title = (t['trackName'] as String? ?? '').toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (title.isNotEmpty && !seen.add(title)) continue;
        tracks.add(_toTrack(t));
      }
      _artistTracksCache[artistName] = tracks;
      return tracks;
    } catch (e) {
      debugPrint('ItunesService: fetchArtistTopTracks error: $e');
      return [];
    }
  }

  static Future<List<HomeAlbum>> fetchArtistAlbums(String artistName) async {
    if (_artistAlbumsCache.containsKey(artistName)) return _artistAlbumsCache[artistName]!;
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': artistName, 'media': 'music', 'entity': 'album', 'limit': 15,
      });
      final albums = <HomeAlbum>[];
      for (final a in _extractResults(r.data)) {
        final title = a['collectionName'] as String? ?? '';
        final img = _artwork(a['artworkUrl100'] as String? ?? '');
        albums.add(HomeAlbum(
          title: title, artist: a['artistName'] as String? ?? artistName,
          image: img, imageUrl: img,
          trackCount: _toInt(a['trackCount']),
          year: (a['releaseDate'] as String? ?? '').split('-').first,
          collectionId: a['collectionId'] as int?,
        ));
      }
      _artistAlbumsCache[artistName] = albums;
      return albums;
    } catch (e) {
      debugPrint('ItunesService: fetchArtistAlbums error: $e');
      return [];
    }
  }

  static Future<List<HomeTrack>> fetchAlbumTracksByTitle(String albumTitle, String artistName) async {
    final key = '$albumTitle|||$artistName';
    if (_albumTracksCache.containsKey(key)) return _albumTracksCache[key]!;
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': '$albumTitle $artistName', 'media': 'music', 'entity': 'song', 'limit': 50,
      });
      final results = _extractResults(r.data);
      final tLow = albumTitle.toLowerCase();
      var tracks = results.where((t) {
        final collection = (t['collectionName'] as String? ?? '').toLowerCase();
        return collection == tLow;
      }).map((t) => _toTrack(t)).toList();
      if (tracks.isEmpty) {
        tracks = results.where((t) {
          final collection = (t['collectionName'] as String? ?? '').toLowerCase();
          return collection.contains(tLow) || tLow.contains(collection);
        }).map((t) => _toTrack(t)).toList();
      }
      if (tracks.isEmpty) {
        tracks = results.map((t) => _toTrack(t)).toList();
      }
      _albumTracksCache[key] = tracks;
      return tracks;
    } catch (e) {
      debugPrint('ItunesService: fetchAlbumTracksByTitle error: $e');
      return [];
    }
  }

  static Future<List<HomeTrack>> fetchAlbumTracks(int collectionId) async {
    try {
      final r = await _dio.get('$_base/lookup', queryParameters: {
        'id': collectionId, 'entity': 'song', 'limit': 100,
      });
      return _extractResults(r.data)
          .where((t) => t['wrapperType'] == 'track')
          .map((t) => _toTrack(t))
          .toList();
    } catch (e) {
      debugPrint('ItunesService: fetchAlbumTracks error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> fetchAlbumMetadata(int collectionId) async {
    try {
      final r = await _dio.get('$_base/lookup', queryParameters: {
        'id': collectionId, 'entity': 'song', 'limit': 1,
      });
      final results = _extractResults(r.data);
      if (results.isEmpty) return null;
      final f = results.first as Map;
      return {
        'trackCount': _toInt(f['trackCount']),
        'collectionName': f['collectionName'] as String? ?? '',
        'artistName': f['artistName'] as String? ?? '',
        'artworkUrl100': f['artworkUrl100'] as String?,
        'releaseDate': f['releaseDate'] as String?,
        'collectionId': f['collectionId'],
      };
    } catch (e) {
      debugPrint('ItunesService: fetchAlbumMetadata error: $e');
      return null;
    }
  }

  static Future<List<Map<String, String>>> fetchArtistPlaylists(String artistName, {int limit = 5}) async {
    if (_artistPlaylistsCache.containsKey(artistName)) return _artistPlaylistsCache[artistName]!;
    try {
      final r = await _dio.get('$_base/search', queryParameters: {
        'term': '$artistName best of', 'media': 'music', 'entity': 'album', 'limit': limit,
      });
      final playlists = <Map<String, String>>[];
      for (final a in _extractResults(r.data)) {
        final title = a['collectionName'] as String? ?? '';
        final img = _artwork(a['artworkUrl100'] as String? ?? '');
        if (title.isEmpty || img.isEmpty) continue;
        playlists.add({'title': title, 'image': img, 'id': '${a['collectionId'] ?? ''}', 'trackCount': '${_toInt(a['trackCount'])}'});
      }
      _artistPlaylistsCache[artistName] = playlists;
      return playlists;
    } catch (e) {
      debugPrint('ItunesService: fetchArtistPlaylists error: $e');
      return [];
    }
  }

  static Future<List<HomeTrack>> fetchPlaylistTracks(String playlistId) async {
    try {
      final r = await _dio.get('$_base/lookup', queryParameters: {
        'id': playlistId, 'entity': 'song', 'limit': 100,
      });
      return _extractResults(r.data).where((t) => t['wrapperType'] == 'track').map((t) => _toTrack(t)).toList();
    } catch (e) {
      debugPrint('ItunesService: fetchPlaylistTracks error: $e');
      return [];
    }
  }
}
