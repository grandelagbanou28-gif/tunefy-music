import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';

final ccmixterApiServiceProvider = Provider<CcMixterApiService>((ref) {
  return CcMixterApiService();
});

/// ccMixter Query API 2.0 — Creative Commons music, **no key required**.
///
/// Real uploads are tagged by genre and hosted as full-length MP3 files
/// (CC-licensed, some royalty-free). The JSON search result gives the upload
/// page URL; the streamable file is resolved from that page (one extra call).
/// Items map to directly playable `user_track`s exactly like Jamendo/Audius.
/// Provenance is stamped on every item. Never throws — failures return [] so
/// the pipeline falls through cleanly.
class CcMixterApiService {
  static const String _base = 'https://ccmixter.org/api/query';
  static const Duration _timeout = Duration(seconds: 8);

  /// Full-length CC track files, one per upload.
  Future<List<MuzoItem>> tracksByTag(String tag, {int limit = 6}) async {
    final t = tag.trim().toLowerCase();
    if (t.isEmpty) return const [];
    try {
      final uri = Uri.parse(
        '$_base?datasource=uploads&f=json&t=search_uploads'
        '&search_type=any&s=${Uri.encodeComponent(t)}&limit=$limit',
      );
      final resp = await http.get(uri).timeout(_timeout);
      if (resp.statusCode != 200) {
        debugPrint('ccMixter non-200: ${resp.statusCode}');
        return const [];
      }
      final raw = jsonDecode(resp.body);
      if (raw is Map && raw['status'] != null) {
        // API error payloads are {"status": "..."} dictionaries.
        debugPrint('ccMixter error: $raw');
        return const [];
      }
      final list =
          raw is List ? raw : (raw is Map ? raw['uploads'] as List? : null);
      if (list == null) return const [];

      final futures = <Future<MuzoItem?>>[
        for (final e in list.whereType<Map>().take(limit))
          _itemFromUpload(Map<String, dynamic>.from(e)),
      ];
      final items = await Future.wait(futures, eagerError: false);
      return [for (final i in items) if (i != null) i];
    } catch (e) {
      debugPrint('ccMixter error: $e');
      return const [];
    }
  }

  Future<MuzoItem?> _itemFromUpload(Map<String, dynamic> m) async {
    final name = m['upload_name']?.toString() ?? '';
    final pageUrl = m['file_page_url']?.toString() ?? '';
    final id = m['upload_id']?.toString() ?? '';
    if (name.isEmpty || pageUrl.isEmpty) return null;
    try {
      final url = await _resolveFileUrl(pageUrl);
      if (url == null) return null;
      final artist = _artistName(m);
      return MuzoItem(
        title: name,
        thumbnails: const [],
        resultType: 'user_track',
        isExplicit: false,
        videoId: 'ccm_$id',
        artists: artist.isNotEmpty ? [MuzoArtist(name: artist, id: null)] : null,
        channelName: artist.isEmpty ? null : artist,
        description: m['qsearch']?.toString(),
        audioUrl: url,
        source: 'ccmixter',
        sourceId: id,
        sourceUrl: pageUrl,
        fetchedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  /// The upload page embeds the real stream URL as
  /// `https://ccmixter.org/content/{user}/{artist_-_name}.mp3`. One extra
  /// request per upload, bounded and skipped on any failure.
  Future<String?> _resolveFileUrl(String pageUrl) async {
    try {
      final resp = await http.get(Uri.parse(pageUrl)).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final html = resp.body;
      final match = RegExp(r'ccmixter\.org/content/[0-9A-Za-z_\-/.]+\.mp3')
          .firstMatch(html);
      return match == null
          ? null
          : 'https://${match.group(0)}';
    } catch (e) {
      debugPrint('ccMixter page error: $e');
      return null;
    }
  }

  String _artistName(Map<String, dynamic> m) {
    for (final k in ['upload_artist', 'user_real_name', 'user_name']) {
      final raw = m[k];
      final v = raw is String ? raw.trim() : '';
      if (v.isNotEmpty && v != 'undefined') return v;
    }
    return '';
  }
}