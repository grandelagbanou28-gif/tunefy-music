import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tunefy/models/home_track.dart';

class CatalogAlbum {
  final String id;
  final String title;
  final String artist;
  final String? imageUrl;
  final int trackCount;
  final String source;

  const CatalogAlbum({
    required this.id,
    required this.title,
    required this.artist,
    this.imageUrl,
    this.trackCount = 0,
    this.source = 'audius',
  });
}

class CatalogPlaylist {
  final String id;
  final String title;
  final String? description;
  final String? imageUrl;
  final int trackCount;
  final String source;

  const CatalogPlaylist({
    required this.id,
    required this.title,
    this.description,
    this.imageUrl,
    this.trackCount = 0,
    this.source = 'audius',
  });
}

class CatalogTrack {
  final String id;
  final String title;
  final String artist;
  final String? imageUrl;
  final String? streamUrl;
  final String? previewUrl;
  final int durationMs;
  final String? albumName;
  final String source;

  const CatalogTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.imageUrl,
    this.streamUrl,
    this.previewUrl,
    this.durationMs = 0,
    this.albumName,
    this.source = 'audius',
  });
}

class MusicCatalogService {
  static const _audiusBase = 'https://discoveryprovider.audius.co/v1';
  static const _jamendoBase = 'https://api.jamendo.com/v3.0';
  static const _jamendoClientId = '709fa152';

  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  // ─── Public search methods ─────────────────────────────────

  static Future<List<CatalogAlbum>> searchAlbums(String query, {int limit = 20}) async {
    final results = await _searchAudiusAlbums(query, limit);
    if (results.isNotEmpty) return results;
    return _searchJamendoAlbums(query, limit);
  }

  static Future<List<CatalogPlaylist>> searchPlaylists(String query, {int limit = 20}) async {
    final results = await _searchAudiusPlaylists(query, limit);
    if (results.isNotEmpty) return results;
    return _searchJamendoPlaylists(query, limit);
  }

  static Future<List<CatalogTrack>> getAlbumTracks(String albumId, {String source = 'audius'}) async {
    if (source == 'jamendo') return _getJamendoAlbumTracks(albumId);
    return _getAudiusPlaylistTracks(albumId);
  }

  static Future<List<CatalogTrack>> getPlaylistTracks(String playlistId, {String source = 'audius'}) async {
    if (source == 'jamendo') return _getJamendoPlaylistTracks(playlistId);
    return _getAudiusPlaylistTracks(playlistId);
  }

  static Future<List<CatalogTrack>> searchTracks(String query, {int limit = 20}) async {
    final results = await _searchAudiusTracks(query, limit);
    if (results.isNotEmpty) return results;
    return _searchJamendoTracks(query, limit);
  }

  // ─── Audius ────────────────────────────────────────────────

  static Future<List<CatalogAlbum>> _searchAudiusAlbums(String query, int limit) async {
    try {
      final r = await _dio.get('$_audiusBase/search/full', queryParameters: {'query': query, 'limit': limit, 'kind': 'albums'});
      final data = _decode(r.data);
      final albums = data['data'] as List?;
      if (albums == null || albums.isEmpty) return [];
      return albums.whereType<Map>().map((a) => _audiusAlbumToCatalog(a)).toList();
    } catch (e) {
      debugPrint('MusicCatalog: Audius albums search error: $e');
      return [];
    }
  }

  static Future<List<CatalogPlaylist>> _searchAudiusPlaylists(String query, int limit) async {
    try {
      final r = await _dio.get('$_audiusBase/search/full', queryParameters: {'query': query, 'limit': limit, 'kind': 'playlists'});
      final data = _decode(r.data);
      final playlists = data['data'] as List?;
      if (playlists == null || playlists.isEmpty) return [];
      return playlists.whereType<Map>().map((p) => _audiusPlaylistToCatalog(p)).toList();
    } catch (e) {
      debugPrint('MusicCatalog: Audius playlists search error: $e');
      return [];
    }
  }

  static Future<List<CatalogTrack>> _searchAudiusTracks(String query, int limit) async {
    try {
      final r = await _dio.get('$_audiusBase/search/full', queryParameters: {'query': query, 'limit': limit, 'kind': 'tracks'});
      final data = _decode(r.data);
      final tracks = data['data'] as List?;
      if (tracks == null || tracks.isEmpty) return [];
      return tracks.whereType<Map>().map((t) => _audiusTrackToCatalog(t)).toList();
    } catch (e) {
      debugPrint('MusicCatalog: Audius tracks search error: $e');
      return [];
    }
  }

  static Future<List<CatalogTrack>> _getAudiusPlaylistTracks(String playlistId) async {
    try {
      final r = await _dio.get('$_audiusBase/playlists/$playlistId');
      final data = _decode(r.data);
      final playlist = data['data'] as List?;
      if (playlist == null || playlist.isEmpty) return [];
      final tracks = (playlist.first is Map ? playlist.first['tracks'] : null) as List?;
      if (tracks == null || tracks.isEmpty) return [];
      return tracks.whereType<Map>().map((t) => _audiusTrackToCatalog(t)).toList();
    } catch (e) {
      debugPrint('MusicCatalog: Audius playlist tracks error: $e');
      return [];
    }
  }

  static CatalogAlbum _audiusAlbumToCatalog(Map a) {
    return CatalogAlbum(
      id: (a['id'] ?? '').toString(),
      title: a['title'] as String? ?? a['playlist_name'] as String? ?? '',
      artist: a['artist_name'] as String? ?? a['user']?['name'] as String? ?? '',
      imageUrl: a['artwork']?['150x150'] as String? ?? a['playlist_image'] as String? ?? _audiusCover(a),
      trackCount: _toInt(a['track_count'] ?? a['playlist_contents']?['track_ids']?.length ?? 0),
      source: 'audius',
    );
  }

  static CatalogPlaylist _audiusPlaylistToCatalog(Map p) {
    return CatalogPlaylist(
      id: (p['id'] ?? '').toString(),
      title: p['title'] as String? ?? p['playlist_name'] as String? ?? '',
      description: p['description'] as String?,
      imageUrl: p['artwork']?['150x150'] as String? ?? p['playlist_image'] as String? ?? _audiusCover(p),
      trackCount: _toInt(p['track_count'] ?? p['playlist_contents']?['track_ids']?.length ?? 0),
      source: 'audius',
    );
  }

  static CatalogTrack _audiusTrackToCatalog(Map t) {
    return CatalogTrack(
      id: (t['id'] ?? '').toString(),
      title: t['title'] as String? ?? '',
      artist: t['user']?['name'] as String? ?? t['artist_name'] as String? ?? '',
      imageUrl: t['artwork']?['150x150'] as String? ?? _audiusCover(t),
      streamUrl: t['id'] != null ? '$_audiusBase/tracks/${t['id']}/stream' : null,
      durationMs: _toInt(t['duration']),
      albumName: t['album']?['title'] as String? ?? t['playlist_name'] as String?,
      source: 'audius',
    );
  }

  static String? _audiusCover(Map m) {
    final cid = m['cover_art'] as String? ?? m['cover_art_sizes'] as String?;
    if (cid == null) return null;
    return 'https://creatornode.audius.co/ipfs/$cid/150x150.jpg';
  }

  // ─── Jamendo ───────────────────────────────────────────────

  static Future<List<CatalogAlbum>> _searchJamendoAlbums(String query, int limit) async {
    try {
      final r = await _dio.get('$_jamendoBase/albums', queryParameters: {
        'client_id': _jamendoClientId, 'format': 'json', 'limit': limit,
        'namesearch': query, 'order': 'popularity_total_desc',
      });
      final data = _decodeJamendo(r.data);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return [];
      return results.whereType<Map>().map((a) => CatalogAlbum(
        id: (a['id'] ?? '').toString(),
        title: a['name'] as String? ?? '',
        artist: a['artist_name'] as String? ?? '',
        imageUrl: a['image'] as String?,
        trackCount: _toInt(a['tracks']?.length ?? 0),
        source: 'jamendo',
      )).toList();
    } catch (e) {
      debugPrint('MusicCatalog: Jamendo albums search error: $e');
      return [];
    }
  }

  static Future<List<CatalogPlaylist>> _searchJamendoPlaylists(String query, int limit) async {
    try {
      final r = await _dio.get('$_jamendoBase/playlists', queryParameters: {
        'client_id': _jamendoClientId, 'format': 'json', 'limit': limit,
        'namesearch': query,
      });
      final data = _decodeJamendo(r.data);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return [];
      return results.whereType<Map>().map((p) => CatalogPlaylist(
        id: (p['id'] ?? '').toString(),
        title: p['name'] as String? ?? '',
        description: p['description'] as String?,
        imageUrl: p['image'] as String?,
        trackCount: _toInt(p['tracks']?.length ?? 0),
        source: 'jamendo',
      )).toList();
    } catch (e) {
      debugPrint('MusicCatalog: Jamendo playlists search error: $e');
      return [];
    }
  }

  static Future<List<CatalogTrack>> _getJamendoAlbumTracks(String albumId) async {
    try {
      final r = await _dio.get('$_jamendoBase/albums/tracks', queryParameters: {
        'client_id': _jamendoClientId, 'format': 'json', 'id': albumId, 'limit': '100',
      });
      return _parseJamendoTracks(r.data);
    } catch (e) {
      debugPrint('MusicCatalog: Jamendo album tracks error: $e');
      return [];
    }
  }

  static Future<List<CatalogTrack>> _getJamendoPlaylistTracks(String playlistId) async {
    try {
      final r = await _dio.get('$_jamendoBase/playlists/tracks', queryParameters: {
        'client_id': _jamendoClientId, 'format': 'json', 'id': playlistId, 'limit': '100',
      });
      return _parseJamendoTracks(r.data);
    } catch (e) {
      debugPrint('MusicCatalog: Jamendo playlist tracks error: $e');
      return [];
    }
  }

  static Future<List<CatalogTrack>> _searchJamendoTracks(String query, int limit) async {
    try {
      final r = await _dio.get('$_jamendoBase/tracks', queryParameters: {
        'client_id': _jamendoClientId, 'format': 'json', 'limit': limit,
        'search': query, 'order': 'popularity_total_desc',
      });
      return _parseJamendoTracks(r.data);
    } catch (e) {
      debugPrint('MusicCatalog: Jamendo tracks search error: $e');
      return [];
    }
  }

  static List<CatalogTrack> _parseJamendoTracks(dynamic raw) {
    try {
      final data = _decodeJamendo(raw);
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return [];
      return results.whereType<Map>().expand((r) {
        final albumName = r['name'] as String?;
        final albumArtist = r['artist_name'] as String?;
        final albumImage = r['image'] as String?;
        final tracks = r['tracks'] as List?;
        if (tracks == null || tracks.isEmpty) return <CatalogTrack>[];
        return tracks.whereType<Map>().map((t) => CatalogTrack(
          id: (t['id'] ?? '').toString(),
          title: t['name'] as String? ?? '',
          artist: albumArtist ?? '',
          imageUrl: t['image'] as String? ?? albumImage,
          streamUrl: t['audio'] as String?,
          previewUrl: t['audiodownload'] as String?,
          durationMs: _toInt(t['duration']) * 1000,
          albumName: albumName,
          source: 'jamendo',
        ));
      }).toList();
    } catch (e) {
      debugPrint('MusicCatalog: parse Jamendo tracks error: $e');
      return [];
    }
  }

  // ─── Helpers ───────────────────────────────────────────────

  static Map<String, dynamic> _decode(dynamic raw) {
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    if (raw is Map) return raw as Map<String, dynamic>;
    return {};
  }

  static Map<String, dynamic> _decodeJamendo(dynamic raw) {
    if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    if (raw is Map) return raw as Map<String, dynamic>;
    return {};
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    if (v is double) return v.toInt();
    return 0;
  }
}
