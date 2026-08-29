import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';

final musicBrainzServiceProvider = Provider<MusicBrainzService>((ref) {
  return MusicBrainzService();
});

/// MusicBrainz API — free, no key needed. Metadata + search.
class MusicBrainzService {
  static const _base = 'https://musicbrainz.org/ws/2';
  static const _timeout = Duration(seconds: 12);
  static const _ua = 'MuzoTunefy/1.0 ( contact@muzo.app )';

  final Map<String, MusicBrainzArtist?> _artistCache = {};

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

  // ── Artist validation (geo + genre evidence) ──────────────────────────────

  static const Map<String, String> _countryName = {
    'US': 'usa',
    'GB': 'uk',
    'FR': 'france',
    'BJ': 'benin',
    'NG': 'nigeria',
    'GH': 'ghana',
    'ZA': 'south africa',
    'KE': 'kenya',
    'TZ': 'east africa',
    'UG': 'east africa',
    'RW': 'east africa',
    'ET': 'east africa',
    'SN': 'west africa',
    'ML': 'west africa',
    'CI': 'west africa',
    'TG': 'west africa',
    'BF': 'west africa',
    'CM': 'africa',
    'CG': 'africa',
    'CD': 'africa',
    'JM': 'caribbean',
    'TT': 'caribbean',
    'BB': 'caribbean',
    'HT': 'caribbean',
    'CU': 'caribbean',
    'DO': 'caribbean',
    'PR': 'caribbean',
    'BR': 'brazil',
    'IN': 'india',
  };

  /// Look up one artist: country/area + genres. Cached per name in memory.
  Future<MusicBrainzArtist?> findArtist(String name) async {
    final key = name.trim().toLowerCase();
    if (key.isEmpty) return null;
    if (_artistCache.containsKey(key)) return _artistCache[key];
    try {
      final uri = Uri.parse(
          '$_base/artist/?query=${Uri.encodeComponent('artist:"$name"')}'
          '&fmt=json&limit=1');
      final resp =
          await http.get(uri, headers: {'User-Agent': _ua}).timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final data = json.decode(resp.body) as Map<String, dynamic>;
      final artists = data['artists'] as List? ?? [];
      if (artists.isEmpty) {
        _artistCache[key] = null;
        return null;
      }
      final a = Map<String, dynamic>.from(artists.first as Map);
      final area = a['area'] as Map?;
      final country = a['country']?.toString() ??
          area?['country-code']?.toString() ??
          '';
      final genres = <String>[
        for (final g in (a['genres'] as List? ?? []))
          if (g is Map) g['name']?.toString() ?? '',
        for (final g in (a['tags'] as List? ?? []))
          if (g is Map) g['name']?.toString() ?? '',
      ].where((s) => s.isNotEmpty).toList();
      final info = MusicBrainzArtist(
        country: country,
        area: area?['name']?.toString(),
        sortName: a['sort-name']?.toString(),
        genres: genres.toSet().toList(),
      );
      _artistCache[key] = info;
      return info;
    } catch (e) {
      debugPrint('MusicBrainz findArtist error: $e');
      _artistCache[key] = null;
      return null;
    }
  }

  /// Authoritative rescue for a strict-gate rejection: keep only candidates
  /// whose artist is country/region confirmed by MusicBrainz (and, when a
  /// genre is given, on-genre too). Real evidence — never a guess. Returns a
  /// subset of [candidates], stamped `verified` with their evidence score.
  Future<List<MuzoItem>> rescueMatches(
    List<MuzoItem> candidates, {
    required String geo,
    String? genre,
  }) async {
    final out = <MuzoItem>[];
    for (final item in candidates.take(6)) {
      final artist = item.artists?.isNotEmpty == true
          ? item.artists!.first.name
          : item.displayArtist.trim().split(RegExp(r'\s+-\s+')).first;
      if (artist.trim().isEmpty) continue;
      final info = await findArtist(artist);
      if (info == null) continue;
      var matched = false;
      final evidence = <String>[];
      if (info.country.isNotEmpty) {
        final geoName = _countryName[info.country.toUpperCase()];
        if (geoName != null && _geoContains(geo, geoName)) {
          matched = true;
          evidence.add('country:${info.country}');
        }
      }
      if (genre != null && genre.isNotEmpty) {
        final g = _norm(genre);
        for (final mbGenre in info.genres) {
          if (_norm(mbGenre).contains(g) || g.contains(_norm(mbGenre))) {
            matched = true;
            evidence.add('genre:$mbGenre');
            break;
          }
        }
      }
      if (matched) {
        out.add(item.copyWith(
          verified: true,
          relevanceScore: 85,
          metadata: {'musicbrainz': evidence},
        ));
      }
    }
    return out;
  }

  bool _geoContains(String geo, String country) {
    final g = geo.trim().toLowerCase();
    if (g == country) return true;
    switch (g) {
      case 'west africa':
        return const {'benin', 'nigeria', 'ghana'}.contains(country);
      case 'east africa':
        return const {'east africa', 'kenya'}.contains(country);
      case 'africa':
        return const {
          'benin',
          'nigeria',
          'ghana',
          'south africa',
          'kenya',
          'east africa',
          'west africa',
        }.contains(country);
      case 'caribbean':
        return const {'caribbean', 'jamaica'}.contains(country);
      default:
        return false;
    }
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\u00e0-\u00ff]'), '')
      .trim();
}

/// Verified evidence about one artist from the MusicBrainz database.
class MusicBrainzArtist {
  final String country;
  final String? area;
  final String? sortName;
  final List<String> genres;

  const MusicBrainzArtist({
    this.country = '',
    this.area,
    this.sortName,
    this.genres = const [],
  });
}
