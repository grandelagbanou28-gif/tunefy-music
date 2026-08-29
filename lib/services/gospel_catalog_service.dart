import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/gospel_artist.dart';
import 'package:muzo/services/gospel_artist_database.dart';
import 'package:muzo/services/supabase_store.dart';

/// Loads the big `gospel_artists` catalog from Supabase and feeds it to the
/// gospel gate (`gospel_artist_database.dart`).
///
/// Order of preference: live REST → Hive cache → built-in curated list. The
/// app therefore works offline and before the DB is seeded.
class GospelCatalogService {
  static const String _cacheKey = 'gospel_catalog';

  static const Map<String, String> _geoByCode = {
    'BJ': 'benin',
    'NG': 'nigeria',
    'GH': 'ghana',
    'ZA': 'south africa',
    'KE': 'kenya',
    'US': 'usa',
    'FR': 'france',
    'CA': 'canada',
    // Central/West African artists not mapped to a dedicated country key live
    // under the continent entry (matches the built-in gate behaviour).
    'CI': 'africa',
    'CD': 'africa',
    'GB': 'africa',
  };

  List<GospelArtist> _catalog = const [];

  /// Sorted catalog currently in memory.
  List<GospelArtist> get catalog => _catalog;

  /// Fetch the full catalog. Never throws: on any failure it degrades to the
  /// Hive cache, then to the built-in list.
  Future<List<GospelArtist>> loadAll() async {
    try {
      final resp = await http.get(
        Uri.parse(
          '${SupabaseStore.url}/rest/v1/gospel_artists?select=*&order=name.asc&limit=4000',
        ),
        headers: {'apikey': SupabaseStore.anonKey},
      );
      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final rows = (jsonDecode(resp.body) as List)
            .map((e) => GospelArtist.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _cache(rows);
        _catalog = rows;
        return rows;
      }
    } catch (e) {
      debugPrint('Gospel catalog REST failed: $e');
    }

    final cached = _readCache();
    if (cached.isNotEmpty) {
      _catalog = cached;
      return cached;
    }
    return _builtin();
  }

  /// Loads the catalog and updates the gospel gate with the DB-backed list.
  Future<void> init() async {
    final all = await loadAll();
    if (all.isEmpty) return;
    final byGeo = <String, List<String>>{};
    for (final a in all) {
      final geo = _geoByCode[(a.countryCode ?? '').toUpperCase()];
      if (geo == null) continue;
      byGeo.putIfAbsent(geo, () => []).add(a.name);
    }
    setGospelSupplement(byGeo);
    debugPrint('Gospel catalog loaded: ${all.length} artists from DB');
  }

  List<GospelArtist> _builtin() {
    final rows = <GospelArtist>[];
    builtinGospelByGeo().forEach((geo, names) {
      for (final name in names) {
        rows.add(GospelArtist(name: name, type: 'artist', verified: false));
      }
    });
    _catalog = rows;
    return rows;
  }

  void _cache(List<GospelArtist> rows) {
    try {
      Hive.box('settings').put(
        _cacheKey,
        jsonEncode(rows.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Could not cache gospel catalog: $e');
    }
  }

  List<GospelArtist> _readCache() {
    try {
      final raw = Hive.box('settings').get(_cacheKey);
      if (raw is String && raw.isNotEmpty) {
        return (jsonDecode(raw) as List)
            .map((e) => GospelArtist.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('Gospel catalog cache read failed: $e');
    }
    return const [];
  }
}