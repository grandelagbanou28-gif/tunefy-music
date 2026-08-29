import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';

final internetArchiveServiceProvider = Provider<InternetArchiveService>((ref) {
  return InternetArchiveService();
});

/// Internet Archive advanced-search + metadata — free, **no key required**,
/// CORS-enabled.
///
/// Millions of real audio items (music collections per genre, world music,
/// podcasts, radio). Items are streamed as full-length MP3 files directly
/// from archive.org, mapped to playable `user_track`s. Two calls per item
/// (search + metadata); everything is defensive — failures return [] and the
/// pipeline falls through.
class InternetArchiveService {
  static const String _base = 'https://archive.org';
  static const Duration _searchTimeout = Duration(seconds: 10);
  static const Duration _metaTimeout = Duration(seconds: 8);

  /// Real audio files whose metadata matches [term].
  Future<List<MuzoItem>> audioByTerm(String term, {int limit = 4}) async {
    final t = term.trim();
    if (t.isEmpty) return const [];
    try {
      final q =
          '${_escapeQ(t)} AND mediatype:audio'
          ' AND NOT (identifier:test* OR collection:testplayer)';
      final uri = Uri.parse(_base +
          '/advancedsearch.php?q=${Uri.encodeComponent(q)}&fl[]=identifier'
          '&fl[]=title&rows=${limit.clamp(1, 8)}&page=1&output=json');
      final resp = await http.get(uri).timeout(_searchTimeout);
      if (resp.statusCode != 200) {
        debugPrint('IA search non-200: ${resp.statusCode}');
        return const [];
      }
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final docs =
          ((data['response'] as Map?)?['docs'] as List?) ?? const [];
      if (docs.isEmpty) return const [];

      final futures = docs
          .whereType<Map>()
          .map((e) => _itemFromDoc(Map<String, dynamic>.from(e)))
          .toList();
      final batches = await Future.wait(futures, eagerError: false);
      return [for (final b in batches) ...b];
    } catch (e) {
      debugPrint('IA search error: $e');
      return const [];
    }
  }

  Future<List<MuzoItem>> _itemFromDoc(Map<String, dynamic> doc) async {
    final id = doc['identifier']?.toString() ?? '';
    final title = doc['title']?.toString() ?? '';
    if (id.isEmpty || title.isEmpty) return const [];
    try {
      final metaResp =
          await http.get(Uri.parse('$_base/metadata/$id')).timeout(_metaTimeout);
      if (metaResp.statusCode != 200) return const [];
      final meta = jsonDecode(metaResp.body) as Map<String, dynamic>;
      final metadata = (meta['metadata'] as Map?) ?? const {};
      final files = (meta['files'] as List?) ?? const [];

      final mp3 = _bestMp3(files.whereType<Map>());
      if (mp3 == null) return const [];
      final artist = metadata['creator']?.toString() ??
          metadata['artist']?.toString() ??
          title;

      return [
        MuzoItem(
          title: title,
          thumbnails: const [],
          resultType: 'user_track',
          isExplicit: false,
          videoId: 'ia_$id',
          artists: artist.isNotEmpty
              ? [MuzoArtist(name: artist, id: null)]
              : null,
          channelName: artist.isEmpty ? null : artist,
          description: metadata['description']?.toString(),
          audioUrl: '$_base/download/$id/${Uri.encodeComponent(mp3)}',
          source: 'internet archive',
          sourceId: id,
          sourceUrl: '$_base/details/$id',
          fetchedAt: DateTime.now(),
        ),
      ];
    } catch (e) {
      return const [];
    }
  }

  /// Pick the best streamable file: original MP3 first, then any MP3/OGG.
  String? _bestMp3(Iterable<Map> files) {
    final byType = <String, String>{};
    for (final f in files) {
      final name = f['name']?.toString() ?? '';
      final type = f['source']?.toString() ?? '';
      final lower = name.toLowerCase();
      if (!lower.endsWith('.mp3') &&
          !lower.endsWith('.ogg') &&
          !lower.endsWith('.m4a')) {
        continue;
      }
      byType.putIfAbsent('$type', () => name);
    }
    if (byType['original'] != null) return byType['original'];
    return byType.values.isNotEmpty ? byType.values.first : null;
  }

  String _escapeQ(String s) =>
      s.split(RegExp(r'\s+')).map((w) => '($w)').join(' AND ');
}