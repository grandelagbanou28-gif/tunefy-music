import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';

/// Piped API client — proxy YouTube sans clé API.
///
/// ⚠️ Réalité terrain (testé août 2026) :
/// - `/search?filter=music_songs` fonctionne bien sur les instances saines
/// - `/streams` (extraction audio) est cassée sur la plupart des instances
///   publiques (YouTube bloque leurs IPs) → garder en dernier recours seulement
/// - La majorité des instances listées sur status.piped.video sont down
///
/// Instances vérifiées manuellement :
/// - api.piped.private.coffee  ✅ search + streams(500 parfois)
/// - pipedapi.lunar.icu        ✅ search uniquement (streams = HTML)
class PipedApiService {
  static const List<String> _instances = [
    'api.piped.private.coffee',
    'pipedapi.lunar.icu',
    'pipedapi.kavin.rocks',
    'pipedapi.drgns.space',
    'piped-api.codespace.cz',
    'piapi.ggtyler.dev',
  ];

  static const Duration _timeout = Duration(seconds: 10);
  final http.Client _client;
  int _instanceIndex = 0;

  PipedApiService({http.Client? client}) : _client = client ?? http.Client();

  String get _baseUrl => 'https://${_instances[_instanceIndex]}';

  void _rotate() {
    _instanceIndex = (_instanceIndex + 1) % _instances.length;
    debugPrint('PipedApi: rotating to ${_instances[_instanceIndex]}');
  }

  /// GET sur l'instance courante, rotation automatique jusqu'à succès.
  Future<http.Response?> _get(String path, {Map<String, String>? query}) async {
    for (var i = 0; i < _instances.length; i++) {
      try {
        final uri = Uri.parse('$_baseUrl$path')
            .replace(queryParameters: query);
        final response =
            await _client.get(uri).timeout(_timeout);
        if (response.statusCode == 200 &&
            response.body.isNotEmpty &&
            response.body.startsWith('{')) {
          return response;
        }
        debugPrint(
            'PipedApi: $path on $_baseUrl → HTTP ${response.statusCode}');
      } catch (e) {
        debugPrint('PipedApi: $path on $_baseUrl → $e');
      }
      _rotate();
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH — le endpoint fiable de Piped
  // ═══════════════════════════════════════════════════════════════════════════

  /// Recherche YouTube music. [filter] muzo : 'songs'|'videos'|'playlists'.
  ///
  /// Retourne des MuzoItem avec videoId exploitables par le player existant
  /// (le stream est résolu ensuite via StreamExtractionService).
  Future<List<MuzoItem>> search(String query,
      {String filter = 'songs'}) async {
    final pipedFilter = switch (filter) {
      'videos' => 'music_videos',
      'albums' => 'music_albums',
      'artists' => 'channels',
      'playlists' => 'playlists',
      _ => 'music_songs',
    };

    final response = await _get('/search', query: {
      'q': query,
      'filter': pipedFilter,
    });
    if (response == null) return [];

    try {
      final data = jsonDecode(response.body);
      final items = data['items'];
      if (items is! List) return [];
      return items.whereType<Map>().map(_itemFromSearch).toList();
    } catch (e) {
      debugPrint('PipedApi: search parse error: $e');
      return [];
    }
  }

  /// Map un item de recherche Piped → MuzoItem.
  ///
  /// Champs Piped réels (vérifiés) :
  ///   url: "/watch?v=ID", title, thumbnail (proxy URL),
  ///   uploaderName, uploaderUrl: "/channel/ID", duration (secondes)
  MuzoItem _itemFromSearch(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final url = map['url']?.toString() ?? '';
    final videoId = url.replaceFirst('/watch?v=', '');
    final uploaderUrl = map['uploaderUrl']?.toString() ?? '';

    return MuzoItem(
      title: map['title']?.toString() ?? 'Unknown Title',
      videoId: videoId.isEmpty ? null : videoId,
      isExplicit: false,
      thumbnails: [
        if (map['thumbnail'] != null)
          MuzoThumbnail(url: map['thumbnail'].toString(), width: 0, height: 0),
      ],
      channelName: map['uploaderName']?.toString(),
      artists: [
        MuzoArtist(
          name: map['uploaderName']?.toString() ?? 'Unknown Artist',
          id: uploaderUrl.replaceFirst('/channel/', ''),
        ),
      ],
      durationSeconds:
          map['duration'] is int && map['duration'] > 0 ? map['duration'] as int : null,
      resultType: map['type']?.toString() == 'playlist' ? 'playlist' : 'song',
      source: 'piped',
      sourceId: videoId.isEmpty ? null : videoId,
      sourceUrl: videoId.isEmpty ? null : 'https://www.youtube.com/watch?v=$videoId',
      fetchedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAMS — dernier recours (cassé sur la plupart des instances publiques)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Meilleure URL de stream audio pour [videoId], ou null.
  Future<String?> getStreamUrl(String videoId) async {
    final response = await _get('/streams/$videoId');
    if (response == null) return null;

    try {
      final data = jsonDecode(response.body);
      final error = data['error'] ?? data['message'];
      if (error != null) {
        debugPrint('PipedApi: streams error: $error');
        return null;
      }
      final streams = data['audioStreams'];
      if (streams is! List || streams.isEmpty) return null;

      // Bitrate le plus proche de 128kbps (qualité medium stable), sinon max
      final candidates = streams
          .whereType<Map>()
          .where((s) => s['url'] != null)
          .toList();
      if (candidates.isEmpty) return null;

      Map closest = candidates.first;
      int bestDiff = 1 << 40;
      for (final s in candidates) {
        final bitrate = (s['bitrate'] is num) ? (s['bitrate'] as num).toInt() : 0;
        final diff = (bitrate - 128000).abs();
        if (diff < bestDiff) {
          bestDiff = diff;
          closest = s;
        }
      }
      final url = closest['url'].toString();
      debugPrint('PipedApi: stream found (${closest['bitrate']} bps)');
      return url;
    } catch (e) {
      debugPrint('PipedApi: streams parse error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PLAYLIST / CHANNEL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pistes d'une playlist YouTube (champ relatedStreams).
  Future<List<MuzoItem>> getPlaylist(String playlistId) async {
    final response = await _get('/playlists/$playlistId');
    if (response == null) return [];
    try {
      final data = jsonDecode(response.body);
      final items = data['relatedStreams'];
      if (items is! List) return [];
      return items.whereType<Map>().map(_itemFromSearch).toList();
    } catch (_) {
      return [];
    }
  }

  /// Vidéos d'une chaîne YouTube.
  Future<List<MuzoItem>> getChannelVideos(String channelId) async {
    final response = await _get('/channel/$channelId');
    if (response == null) return [];
    try {
      final data = jsonDecode(response.body);
      final items = data['relatedStreams'];
      if (items is! List) return [];
      return items.whereType<Map>().map(_itemFromSearch).toList();
    } catch (_) {
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}
