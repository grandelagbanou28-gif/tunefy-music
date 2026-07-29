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

  /// Searches Muzo for the album browseId, returns it.
  /// The album details endpoint is broken (403), so we only return
  /// the browseId for reference — actual tracks must come from iTunes.
  static Future<String?> searchAlbumId(String title, String artist) async {
    try {
      final query = '$title $artist';
      final r = await _dio.get('$_base/api/search', queryParameters: {
        'q': query, 'filter': 'albums', 'limit': '5',
      });
      final raw = r.data;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map) return null;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;

      final tLow = title.toLowerCase();
      final aLow = artist.toLowerCase();
      for (final alb in results) {
        if (alb is! Map) continue;
        final albTitle = (alb['title'] as String? ?? '').toLowerCase();
        final albArtist = (_extractArtist(alb) ?? '').toLowerCase();
        if (albTitle == tLow && (albArtist.contains(aLow) || aLow.contains(albArtist))) {
          return alb['browseId'] as String?;
        }
      }
      return results.firstWhere((a) => a is Map, orElse: () => null)?['browseId'] as String?;
    } catch (e) {
      debugPrint('MuzoService: searchAlbumId error: $e');
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

}
