/// Local artist database service using Hive.
///
/// Stores artist records in Hive for offline access. Seeds with embedded
/// data on first run. Supports full CRUD for admin management.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzo/models/artist_record.dart';

/// Local artist database backed by Hive.
class ArtistLocalService {
  static const String _boxName = 'artist_db';
  static const String _artistsKey = 'artists';
  static const String _initializedKey = 'seeded';

  Box? _box;

  /// Open the Hive box and seed if first run.
  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);

    // Seed embedded data on first launch
    if (!(_box!.get(_initializedKey, defaultValue: false) as bool)) {
      await _saveAll(EmbeddedSeedData.artists);
      await _box!.put(_initializedKey, true);
    }
  }

  Box get _b {
    if (_box == null) throw StateError('ArtistLocalService not initialized');
    return _box!;
  }

  // ─── Read ───

  /// All artists.
  Future<List<ArtistRecord>> getAllArtists() async {
    return _loadAll();
  }

  /// Search by name (fuzzy).
  Future<List<ArtistRecord>> searchByName(String name) async {
    final artists = await getAllArtists();
    final normalized = _normalize(name);
    return artists.where((a) {
      final allNames = a.allNames.map(_normalize).toList();
      return allNames.any((n) =>
          n.contains(normalized) ||
          normalized.contains(n) ||
          _fuzzyMatch(n, normalized));
    }).toList();
  }

  /// All artists for a sub-category.
  Future<List<ArtistRecord>> getBySubCategory(String subCategory) async {
    final artists = await getAllArtists();
    final normalized = _normalize(subCategory);
    return artists.where((a) {
      return a.subCategories
          .any((s) => _normalize(s) == normalized || s.toLowerCase().contains(subCategory.toLowerCase()));
    }).toList();
  }

  /// All artists for a country.
  Future<List<ArtistRecord>> getByCountry(String country) async {
    final artists = await getAllArtists();
    return artists.where((a) => a.hasCountry(country)).toList();
  }

  /// All artists for a genre.
  Future<List<ArtistRecord>> getByGenre(String genre) async {
    final artists = await getAllArtists();
    return artists.where((a) => a.hasGenre(genre)).toList();
  }

  /// Find a matching artist for a sub-category.
  Future<ArtistRecord?> findMatchForSubCategory(
      String artistName, String subCategory) async {
    final candidates = await getBySubCategory(subCategory);
    return _findBestMatch(artistName, candidates);
  }

  // ─── Write ───

  /// Add or update an artist.
  Future<void> saveArtist(ArtistRecord artist) async {
    final artists = await getAllArtists();
    final index = artists.indexWhere((a) => a.id == artist.id);
    if (index >= 0) {
      artists[index] = artist;
    } else {
      artists.add(artist);
    }
    await _saveAll(artists);
  }

  /// Delete an artist by id.
  Future<void> deleteArtist(String id) async {
    final artists = await getAllArtists();
    artists.removeWhere((a) => a.id == id);
    await _saveAll(artists);
  }

  /// Replace all artists (bulk import).
  Future<void> replaceAll(List<ArtistRecord> artists) async {
    await _saveAll(artists);
  }

  /// Reset to embedded seed data.
  Future<void> resetToSeed() async {
    await _saveAll(EmbeddedSeedData.artists);
  }

  // ─── Helpers ───

  ArtistRecord? _findBestMatch(String artistName, List<ArtistRecord> candidates) {
    if (candidates.isEmpty) return null;
    final normalized = _normalize(artistName);

    for (final c in candidates) {
      for (final exclusion in c.exclusions) {
        if (_normalize(exclusion) == normalized) return null;
      }
    }
    for (final c in candidates) {
      if (_normalize(c.name) == normalized) return c;
    }
    for (final c in candidates) {
      for (final alias in c.aliases) {
        if (_normalize(alias) == normalized) return c;
      }
    }
    for (final c in candidates) {
      for (final name in c.allNames) {
        if (_fuzzyMatch(_normalize(name), normalized)) return c;
      }
    }
    return null;
  }

  Future<List<ArtistRecord>> _loadAll() async {
    try {
      final json = _b.get(_artistsKey) as String?;
      if (json == null || json.isEmpty) return EmbeddedSeedData.artists;
      return ArtistRecord.listFromJsonString(json);
    } catch (e) {
      debugPrint('ArtistLocalService: load failed: $e');
      return EmbeddedSeedData.artists;
    }
  }

  Future<void> _saveAll(List<ArtistRecord> artists) async {
    try {
      final json = ArtistRecord.listToJsonString(artists);
      await _b.put(_artistsKey, json);
    } catch (e) {
      debugPrint('ArtistLocalService: save failed: $e');
    }
  }

  // ─── Helpers ───

  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ç', 'c')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _fuzzyMatch(String a, String b) {
    if (a == b) return true;
    if (a.isEmpty || b.isEmpty) return false;
    if (a.contains(b) || b.contains(a)) return true;
    if (a.length <= 30 && b.length <= 30) {
      final distance = _levenshtein(a, b);
      final threshold = (a.length * 0.2).ceil().clamp(1, 3);
      return distance <= threshold;
    }
    return false;
  }

  int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final matrix = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => 0),
    );
    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[a.length][b.length];
  }
}

/// Embedded seed data — the initial set of verified Beninese artists.
class EmbeddedSeedData {
  EmbeddedSeedData._();

  static final List<ArtistRecord> artists = [
    ArtistRecord(
      id: 'sam-bhlu',
      name: 'Sam Bhlu',
      aliases: ['Samson Metonve Houndegla'],
      country: 'Benin',
      genres: ['gospel'],
      subCategories: ['Benin Gospel', 'Worship'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['myaddictive.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'yvan-pour-yesue',
      name: 'Yvan pour Yésué',
      aliases: [],
      country: 'Benin',
      genres: ['gospel'],
      subCategories: ['Benin Gospel', 'Worship'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['myaddictive.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'sir-abile',
      name: 'Sir Abilé',
      aliases: [],
      country: 'Benin',
      genres: ['gospel'],
      subCategories: ['Benin Gospel'],
      confidence: ConfidenceLevel.probable,
      sources: ['myaddictive.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'fanicko',
      name: 'Fanicko',
      aliases: ['Olivier Fanicko Adjanohoun', 'Fanicko de Jésus'],
      country: 'Benin',
      genres: ['gospel', 'urban'],
      subCategories: ['Benin Gospel', 'Top Benin'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['streetartparis.fr'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'le-renoi',
      name: 'Le Renoi',
      aliases: ['Hounye Francois-Xavier Noutin'],
      country: 'Benin',
      genres: ['rap'],
      subCategories: ['Benin Rap', 'Top Benin'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['streetartparis.fr'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'dibi-dobo',
      name: 'Dibi Dobo',
      aliases: [],
      country: 'Benin',
      genres: ['hip-hop', 'rnb'],
      subCategories: ['Benin Rap', 'Top Benin'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['lepetitjournal.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'axel-merryl',
      name: 'Axel Merryl',
      aliases: [],
      country: 'Benin',
      genres: ['afrobeats', 'pop'],
      subCategories: ['Benin Afrobeats', 'Benin Pop', 'Top Benin'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['critikmag.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'nikanor',
      name: 'Nikanor',
      aliases: [],
      country: 'Benin',
      genres: ['afrobeats', 'pop'],
      subCategories: ['Benin Afrobeats', 'Top Benin'],
      confidence: ConfidenceLevel.probable,
      sources: ['redlist.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'santrinos-raphael',
      name: 'Santrinos Raphael',
      aliases: [],
      country: 'Benin',
      genres: ['afrobeats'],
      subCategories: ['Benin Afrobeats', 'Top Benin'],
      confidence: ConfidenceLevel.probable,
      sources: ['redlist.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'vano-baby',
      name: 'Vano Baby',
      aliases: [],
      country: 'Benin',
      genres: ['afrobeats'],
      subCategories: ['Benin Afrobeats', 'Top Benin'],
      confidence: ConfidenceLevel.probable,
      sources: ['redlist.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'madano',
      name: 'Madano',
      aliases: [],
      country: 'Benin',
      genres: ['afrobeats'],
      subCategories: ['Benin Afrobeats', 'Top Benin'],
      confidence: ConfidenceLevel.probable,
      sources: ['redlist.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'gg-lapino',
      name: 'GG Lapino',
      aliases: [],
      country: 'Benin',
      genres: ['afrobeats', 'urban'],
      subCategories: ['Benin Afrobeats', 'Top Benin'],
      confidence: ConfidenceLevel.probable,
      sources: ['streetartparis.fr'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'sessime',
      name: 'Sessimè',
      aliases: [],
      country: 'Benin',
      genres: ['pop', 'world'],
      subCategories: ['Benin Pop', 'Top Benin'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['streetartparis.fr'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'angelique-kidjo',
      name: 'Angélique Kidjo',
      aliases: [],
      country: 'Benin',
      genres: ['world', 'jazz', 'gospel', 'afrobeats'],
      subCategories: ['Benin Afrobeats', 'Afro Hits', 'Top Benin'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['critikmag.com', 'wikipedia.org'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'gangbe-brass-band',
      name: 'Gangbé Brass Band',
      aliases: [],
      country: 'Benin',
      genres: ['jazz', 'traditional'],
      subCategories: ['Afro Hits', 'Jazz'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['lepetitjournal.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'zeynab-habib',
      name: 'Zeynab Habib',
      aliases: [],
      country: 'Benin',
      genres: ['world'],
      subCategories: ['Afro Hits', 'Top Benin'],
      confidence: ConfidenceLevel.confirmed,
      sources: ['lepetitjournal.com', 'wikipedia.org'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'dossi-dossi',
      name: 'Dossi Dossi',
      aliases: [],
      country: 'Benin',
      genres: ['tradi-moderne'],
      subCategories: ['Top Benin'],
      confidence: ConfidenceLevel.probable,
      sources: ['voluncorp.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'teriba',
      name: 'Teriba',
      aliases: [],
      country: 'Benin',
      genres: ['tradi-moderne'],
      subCategories: ['Top Benin'],
      confidence: ConfidenceLevel.probable,
      sources: ['voluncorp.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
    ArtistRecord(
      id: 'sandra-heriti',
      name: 'Sandra Heriti',
      aliases: [],
      country: 'Benin',
      genres: ['gospel'],
      subCategories: ['Benin Gospel'],
      confidence: ConfidenceLevel.probable,
      sources: ['voluncorp.com'],
      dateAdded: '2025-01-01',
      dateLastVerified: '2025-01-01',
    ),
  ];
}