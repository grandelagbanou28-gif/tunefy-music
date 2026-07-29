import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tunefy/models/home_track.dart';

class MuzoService {
  static const _base = 'https://muzo-api.shashwat-coding.workers.dev';
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'User-Agent': 'Tunefy/1.0'},
  ));

  static String? _extractArtist(dynamic item) {
    final artists = item['artists'] as List?;
    if (artists == null || artists.isEmpty) return null;
    for (final a in artists) {
      if (a is Map) {
        final name = a['name'] as String? ?? '';
        if (name.isNotEmpty && name != 'Album' && name != 'Albums') return name;
      }
    }
    return null;
  }

  static String? _extractThumbnail(dynamic thumbnails) {
    if (thumbnails is List && thumbnails.isNotEmpty) {
      final last = thumbnails.last;
      if (last is Map) {
        final url = last['url'] as String?;
        if (url != null && url.isNotEmpty) return url;
      }
    }
    return null;
  }

  static Future<List<HomeAlbum>> searchAlbumsByGenre(String query, {int limit = 10}) async {
    try {
      final r = await _dio.get('$_base/api/search', queryParameters: {
        'q': query, 'filter': 'albums', 'limit': '$limit',
      });
      final raw = r.data;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map) return [];
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return [];
      final albums = <HomeAlbum>[];
      final seen = <String>{};
      for (final a in results) {
        if (a is! Map) continue;
        final browseId = a['browseId'] as String? ?? '';
        if (browseId.isEmpty || !seen.add(browseId)) continue;
        final artist = _extractArtist(a) ?? '';
        final thumb = _extractThumbnail(a['thumbnails']) ?? '';
        final year = a['year'] as String? ?? '';
        albums.add(HomeAlbum(
          title: a['title'] as String? ?? '',
          artist: artist,
          image: thumb,
          imageUrl: thumb,
          year: year,
          browseId: browseId,
        ));
      }
      return albums;
    } catch (e) {
      debugPrint('MuzoService: searchAlbumsByGenre error: $e');
      return [];
    }
  }

  static final _albumBrowseIdCache = <String, String?>{};

  static Future<Map<String, dynamic>?> searchAlbum(String title, String artist) async {
    final cacheKey = '$title|||$artist';
    if (_albumBrowseIdCache.containsKey(cacheKey)) {
      final cachedId = _albumBrowseIdCache[cacheKey];
      if (cachedId != null) return getAlbumDetails(cachedId);
      return null;
    }
    try {
      final query = '$title $artist';
      final r = await _dio.get('$_base/api/search', queryParameters: {
        'q': query, 'filter': 'albums', 'limit': '8',
      });
      final raw = r.data;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map) return _cacheBrowseId(cacheKey, null);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) {
        return await _searchAlbumRetry(title, artist, cacheKey);
      }

      final tLow = title.toLowerCase();
      final aLow = artist.toLowerCase();
      Map? bestMatch;
      double bestScore = 0;

      for (final alb in results) {
        if (alb is! Map) continue;
        final albTitle = (alb['title'] as String? ?? '').toLowerCase();
        final albArtist = (_extractArtist(alb) ?? '').toLowerCase();
        final browseId = alb['browseId'] as String?;
        if (browseId == null || browseId.isEmpty) continue;

        double score = 0;
        if (albTitle == tLow && albArtist == aLow) score = 3;
        else if (albTitle == tLow) score = 2;
        else if ((albTitle.contains(tLow) || tLow.contains(albTitle)) &&
                 (albArtist.contains(aLow) || aLow.contains(albArtist))) score = 1.5;
        else if (albTitle.contains(tLow) || tLow.contains(albTitle)) score = 1;

        if (score > bestScore) {
          bestScore = score;
          bestMatch = alb;
        }
        if (score >= 3) break;
      }

      if (bestMatch != null) {
        final browseId = bestMatch['browseId'] as String;
        final details = await getAlbumDetails(browseId);
        if (details != null) {
          _albumBrowseIdCache[cacheKey] = browseId;
          return details;
        }
      }

      final first = results.first as Map?;
      if (first != null) {
        final browseId = first['browseId'] as String?;
        if (browseId != null && browseId.isNotEmpty) {
          final details = await getAlbumDetails(browseId);
          if (details != null) {
            _albumBrowseIdCache[cacheKey] = browseId;
            return details;
          }
        }
      }

      return await _searchAlbumRetry(title, artist, cacheKey);
    } catch (e) {
      debugPrint('MuzoService: searchAlbum error: $e');
      _albumBrowseIdCache[cacheKey] = null;
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _searchAlbumRetry(String title, String artist, String cacheKey) async {
    try {
      final r = await _dio.get('$_base/api/search', queryParameters: {
        'q': title, 'filter': 'albums', 'limit': '8',
      });
      final raw = r.data;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map) return _cacheBrowseId(cacheKey, null);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return _cacheBrowseId(cacheKey, null);

      final tLow = title.toLowerCase();
      for (final alb in results) {
        if (alb is! Map) continue;
        final albTitle = (alb['title'] as String? ?? '').toLowerCase();
        if (albTitle.contains(tLow) || tLow.contains(albTitle)) {
          final browseId = alb['browseId'] as String?;
          if (browseId != null && browseId.isNotEmpty) {
            final details = await getAlbumDetails(browseId);
            if (details != null) {
              _albumBrowseIdCache[cacheKey] = browseId;
              return details;
            }
          }
        }
      }

      final first = results.first as Map?;
      if (first != null) {
        final browseId = first['browseId'] as String?;
        if (browseId != null && browseId.isNotEmpty) {
          final details = await getAlbumDetails(browseId);
          if (details != null) {
            _albumBrowseIdCache[cacheKey] = browseId;
            return details;
          }
        }
      }
      return _cacheBrowseId(cacheKey, null);
    } catch (_) {
      return _cacheBrowseId(cacheKey, null);
    }
  }

  static Map<String, dynamic>? _cacheBrowseId(String key, String? browseId) {
    _albumBrowseIdCache[key] = browseId;
    return null;
  }

  static Future<Map<String, dynamic>?> getAlbumDetails(String albumId) async {
    try {
      final r = await _dio.get('$_base/api/album/$albumId');
      final raw = r.data;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (e) {
      debugPrint('MuzoService: getAlbumDetails error: $e');
      return null;
    }
  }

  static Future<List<HomeTrack>> searchSongs(String query, {int limit = 30}) async {
    try {
      final r = await _dio.get('$_base/api/search', queryParameters: {
        'q': query, 'filter': 'songs', 'limit': '$limit',
      });
      final raw = r.data;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map) return [];
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return [];
      final seen = <String>{};
      final tracks = <HomeTrack>[];
      for (final s in results) {
        if (s is! Map) continue;
        final videoId = s['videoId'] as String? ?? '';
        if (videoId.isEmpty || !seen.add(videoId)) continue;
        final artist = _extractArtist(s) ?? '';
        final thumb = _extractThumbnail(s['thumbnails']) ?? '';
        tracks.add(HomeTrack(
          videoId: videoId,
          title: s['title'] as String? ?? '',
          artist: artist,
          duration: s['duration'] as String? ?? '',
          imageUrl: thumb,
        ));
      }
      return tracks;
    } catch (e) {
      debugPrint('MuzoService: searchSongs error: $e');
      return [];
    }
  }

  static List<HomeTrack> parseTracks(Map<String, dynamic>? albumData, {String? fallbackArtist, String? fallbackImage}) {
    if (albumData == null) return [];
    final album = albumData['album'] as Map? ?? albumData;
    final albumArtist = album['artist'] as String? ?? fallbackArtist ?? '';
    final albumThumb = album['thumbnail'] as String? ?? fallbackImage ?? '';
    final tracks = album['tracks'] as List?;
    if (tracks == null || tracks.isEmpty) return [];
    return tracks.whereType<Map>().map((t) {
      final videoId = t['videoId'] as String? ?? t['id'] as String? ?? '';
      final trackArtist = t['artist'] as String? ?? '';
      return HomeTrack(
        videoId: videoId,
        title: t['title'] as String? ?? '',
        artist: trackArtist.isNotEmpty ? trackArtist : albumArtist,
        duration: t['duration'] as String? ?? '',
        imageUrl: (t['thumbnail'] as String? ?? '').isNotEmpty
            ? t['thumbnail'] as String
            : albumThumb,
      );
    }).toList();
  }
}
