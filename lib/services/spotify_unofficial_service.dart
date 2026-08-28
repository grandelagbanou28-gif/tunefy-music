import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';

/// Spotify unofficial API — uses public web API without authentication.
class SpotifyUnofficialService {
  static const _base = 'https://api.spotify.com/v1';
  static const _timeout = Duration(seconds: 10);

  /// Search Spotify catalog (requires auth token — we use the public
  /// browse endpoint as a fallback).
  Future<List<MuzoItem>> search(String query) async {
    // Spotify requires OAuth — use the web player token approach.
    try {
      final token = await _getGuestToken();
      if (token == null) return [];
      final uri = Uri.parse(
          '$_base/search?q=${Uri.encodeComponent(query)}&type=track&limit=20');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      }).timeout(_timeout);
      if (resp.statusCode != 200) return [];
      final data = json.decode(resp.body);
      final tracks = data['tracks']?['items'] as List? ?? [];
      return tracks.map<MuzoItem>((t) {
        final name = t['name'] ?? '';
        final artist =
            (t['artists'] as List?)?.isNotEmpty == true
                ? t['artists'][0]['name'] ?? ''
                : '';
        final images = t['album']?['images'] as List? ?? [];
        final thumb = images.isNotEmpty ? images[0]['url'] ?? '' : '';
        final durationMs = t['duration_ms'] ?? 0;
        return MuzoItem(
          videoId: null,
          title: '$name - $artist',
          artists: [MuzoArtist(name: artist, id: null)],
          thumbnails: thumb.isNotEmpty
              ? [MuzoThumbnail(url: thumb, width: 0, height: 0)]
              : [],
          resultType: 'video',
          isExplicit: t['explicit'] ?? false,
          durationSeconds: durationMs > 0 ? (durationMs / 1000).round() : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Spotify search error: $e');
      return [];
    }
  }

  Future<String?> _getGuestToken() async {
    try {
      final resp = await http.post(
        Uri.parse('https://open.spotify.com/get_access_token?reason=transport&productType=web_player'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(_timeout);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        return data['accessToken'];
      }
    } catch (_) {}
    return null;
  }
}
