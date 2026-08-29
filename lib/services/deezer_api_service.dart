import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';

final deezerApiServiceProvider = Provider<DeezerApiService>((ref) {
  return DeezerApiService();
});

/// Deezer public REST API — real catalog metadata, **no key required**.
///
/// Catalog endpoints (search / track / album / artist / genre / chart) are
/// publicly documented. Tracks carry a 30-second preview, which is NOT a real
/// song, so we never expose it as playable audio: Dezeer items are
/// metadata-only seeds (title/artist/album/cover/duration) that callers
/// resolve to full-length playable tracks via the main YouTube search — the
/// same contract as charts seeds. Every item is stamped with real provenance.
class DeezerApiService {
  static const String _base = 'https://api.deezer.com';
  static const Duration _timeout = Duration(seconds: 10);

  // ── Search ────────────────────────────────────────────────────────────────

  /// Real catalog search. Never throws — failures return [] so callers can
  /// fall through to the next source.
  Future<List<MuzoItem>> searchTracks(String query, {int limit = 8}) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final uri = Uri.parse(
          '$_base/search/track?q=${Uri.encodeComponent(q)}&limit=$limit');
      final resp = await http.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) {
        debugPrint('Deezer non-200: ${resp.statusCode}');
        return const [];
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final tracks = data['data'] as List? ?? [];
      return tracks
          .whereType<Map>()
          .map((e) => _trackToMuzo(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Deezer search error: $e');
      return const [];
    }
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  MuzoItem _trackToMuzo(Map<String, dynamic> t) {
    final artist = t['artist'] as Map?;
    final album = t['album'] as Map?;
    final cover =
        album?['cover_medium']?.toString() ?? album?['cover_big']?.toString() ?? '';
    final dur = t['duration'] is int ? (t['duration'] as int?) ?? 0 : 0;
    final id = t['id']?.toString() ?? '';
    final artistName = artist?['name']?.toString() ?? '';
    final albumName = album?['title']?.toString() ?? '';
    final artistId = artist?['id']?.toString();
    return MuzoItem(
      title: t['title']?.toString() ?? '',
      thumbnails: cover.isNotEmpty
          ? [MuzoThumbnail(url: cover, width: 250, height: 250)]
          : const [],
      resultType: 'song',
      isExplicit: t['explicit_lyrics'] == true,
      // Metadata-only id (dz_ prefix) keeps it out of isActuallyPlayable —
      // like it_ singles — until it is resolved to a full YouTube track.
      videoId: id.isEmpty ? null : 'dz_$id',
      durationSeconds: dur,
      duration: dur > 0
          ? '${dur ~/ 60}:${(dur % 60).toString().padLeft(2, '0')}'
          : null,
      artists: artistName.isNotEmpty
          ? [MuzoArtist(name: artistName, id: artistId)]
          : null,
      album: albumName.isNotEmpty ? MuzoAlbum(name: albumName, id: '') : null,
      audioUrl: null,
      source: 'deezer',
      sourceId: id,
      sourceUrl: t['link']?.toString() ?? '',
      fetchedAt: DateTime.now(),
    );
  }
}