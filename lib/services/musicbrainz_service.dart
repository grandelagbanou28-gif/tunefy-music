import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';

/// MusicBrainz API — free, no key needed. Metadata + search.
class MusicBrainzService {
  static const _base = 'https://musicbrainz.org/ws/2';
  static const _timeout = Duration(seconds: 12);
  static const _ua = 'MuzoTunefy/1.0 ( contact@muzo.app )';

  Future<List<MuzoItem>> searchTracks(String query) async {
    try {
      final uri = Uri.parse(
          '$_base/recording/?query=${Uri.encodeComponent(query)}&fmt=json&limit=20');
      final resp =
          await http.get(uri, headers: {'User-Agent': _ua}).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = json.decode(resp.body);
      final recordings = data['recordings'] as List? ?? [];
      return recordings.map<MuzoItem>((r) {
        final title = r['title'] ?? '';
        final artistCredits = r['artist-credit'] as List? ?? [];
        final artist =
            artistCredits.isNotEmpty ? artistCredits[0]['name'] ?? '' : '';
        final durationMs = r['length'] as int? ?? 0;
        return MuzoItem(
          videoId: null,
          title: '$title - $artist',
          artists: [MuzoArtist(name: artist, id: null)],
          thumbnails: [],
          resultType: 'video',
          isExplicit: false,
          durationSeconds: durationMs > 0 ? (durationMs / 1000).round() : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('MusicBrainz search error: $e');
      return [];
    }
  }
}
