/// Artist database service — high-level API for category validation.
///
/// Wraps [ArtistLocalService] and provides the matching logic used by
/// `acceptsForCategory`. This is the single entry point that the rest
/// of the app should use.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/artist_record.dart';
import 'package:muzo/services/neon_database_service.dart';

/// Riverpod provider for the artist database service.
final artistDatabaseServiceProvider = FutureProvider<ArtistDatabaseService>(
  (ref) async {
    final localService = ArtistLocalService();
    await localService.initialize();
    final service = ArtistDatabaseService(localService);
    await service.initialize();
    return service;
  },
);

/// High-level service for artist database lookups.
class ArtistDatabaseService {
  final ArtistLocalService _local;

  /// Public access to the local service for admin operations.
  ArtistLocalService get local => _local;

  /// In-memory lookup cache: normalized artist name → ArtistRecord.
  final Map<String, ArtistRecord> _nameIndex = {};

  /// In-memory lookup cache: normalized (country, genre) → List<ArtistRecord>.
  final Map<String, List<ArtistRecord>> _countryGenreIndex = {};

  /// In-memory lookup cache: normalized sub-category → List<ArtistRecord>.
  final Map<String, List<ArtistRecord>> _subCategoryIndex = {};

  bool _initialized = false;

  ArtistDatabaseService(this._local);

  /// Initialize the service: load artists and build indices.
  Future<void> initialize() async {
    if (_initialized) return;
    final artists = await _local.getAllArtists();
    _buildIndices(artists);
    _initialized = true;
  }

  /// Rebuild indices from the database.
  void _buildIndices(List<ArtistRecord> artists) {
    _nameIndex.clear();
    _countryGenreIndex.clear();
    _subCategoryIndex.clear();

    for (final artist in artists) {
      // Name index: all name forms → record
      for (final name in artist.allNames) {
        final normalized = _normalize(name);
        _nameIndex[normalized] = artist;
      }

      // Country+genre index
      for (final genre in artist.genres) {
        final key = _countryGenreKey(artist.country, genre);
        _countryGenreIndex[key] = [
          ...(_countryGenreIndex[key] ?? []),
          artist,
        ];
      }

      // Sub-category index
      for (final sub in artist.subCategories) {
        final normalized = _normalize(sub);
        _subCategoryIndex[normalized] = [
          ...(_subCategoryIndex[normalized] ?? []),
          artist,
        ];
      }
    }
  }

  /// Find an artist by name (fuzzy, handles aliases and typos).
  /// Returns the matching record, or null.
  ArtistRecord? findByName(String artistName) {
    if (!_initialized) return null;

    final normalized = _normalize(artistName);

    // Direct match
    final direct = _nameIndex[normalized];
    if (direct != null) return direct;

    // Substring / fuzzy match
    for (final entry in _nameIndex.entries) {
      if (_fuzzyMatch(entry.key, normalized)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Find an artist that belongs to a specific sub-category.
  /// Returns the matching record, or null.
  ArtistRecord? findBySubCategory(String artistName, String subCategory) {
    if (!_initialized) return null;

    final normalizedArtist = _normalize(artistName);
    final normalizedSub = _normalize(subCategory);

    final candidates = _subCategoryIndex[normalizedSub] ?? [];
    return _findBestMatch(normalizedArtist, candidates);
  }

  /// Find an artist that belongs to a specific country + genre combination.
  /// Returns the matching record, or null.
  ArtistRecord? findByCountryGenre(
      String artistName, String country, String genre) {
    if (!_initialized) return null;

    final normalizedArtist = _normalize(artistName);
    final key = _countryGenreKey(country, genre);
    final candidates = _countryGenreIndex[key] ?? [];
    return _findBestMatch(normalizedArtist, candidates);
  }

  /// Core matching used by `acceptsForCategory`.
  ///
  /// Given an artist name and a constraint (country + genre or sub-category),
  /// determine if this artist belongs in the category.
  ///
  /// Returns a [MatchResult] with:
  /// - `matched`: whether the artist is in the database for this category
  /// - `record`: the matching artist record (if matched)
  /// - `confidence`: the confidence level of the match
  MatchResult matchForCategory(
    String artistName, {
    String? country,
    String? genre,
    String? subCategory,
  }) {
    if (!_initialized) {
      return const MatchResult(matched: false, record: null);
    }

    ArtistRecord? match;

    // Priority 1: Sub-category match
    if (subCategory != null) {
      match = findBySubCategory(artistName, subCategory);
    }

    // Priority 2: Country + genre match
    if (match == null && country != null && genre != null) {
      match = findByCountryGenre(artistName, country, genre);
    }

    // Priority 3: Global name match (with exclusion check)
    if (match == null) {
      match = findByName(artistName);
    }

    if (match == null) {
      return const MatchResult(matched: false, record: null);
    }

    // Check exclusions
    if (match.exclusions.isNotEmpty) {
      final normalized = _normalize(artistName);
      for (final exclusion in match.exclusions) {
        if (_normalize(exclusion) == normalized) {
          return const MatchResult(matched: false, record: null);
        }
      }
    }

    // Verify the match actually belongs to the requested category
    if (subCategory != null && !match.hasSubCategory(subCategory)) {
      return const MatchResult(matched: false, record: null);
    }
    if (country != null && !match.hasCountry(country)) {
      return const MatchResult(matched: false, record: null);
    }
    if (genre != null && !match.hasGenre(genre)) {
      return const MatchResult(matched: false, record: null);
    }

    return MatchResult(
      matched: true,
      record: match,
      isProbable: match.confidence == ConfidenceLevel.probable,
    );
  }

  /// Get all artists for a sub-category.
  Future<List<ArtistRecord>> getArtistsForSubCategory(String subCategory) {
    return _local.getBySubCategory(subCategory);
  }

  /// Get all artists for a country.
  Future<List<ArtistRecord>> getArtistsForCountry(String country) {
    return _local.getByCountry(country);
  }

  /// Refresh indices from local storage.
  Future<void> refresh() async {
    final artists = await _local.getAllArtists();
    _buildIndices(artists);
  }

  // ─── Helpers ───

  String _countryGenreKey(String country, String genre) {
    return '${_normalize(country)}|${_normalize(genre)}';
  }

  /// Find the best matching artist from a list of candidates.
  ArtistRecord? _findBestMatch(String normalized, List<ArtistRecord> candidates) {
    for (final c in candidates) {
      // Check exclusions first
      bool excluded = false;
      for (final exclusion in c.exclusions) {
        if (_normalize(exclusion) == normalized) {
          excluded = true;
          break;
        }
      }
      if (excluded) continue;

      // Check all name forms
      for (final name in c.allNames) {
        if (_normalize(name) == normalized || _fuzzyMatch(_normalize(name), normalized)) {
          return c;
        }
      }
    }
    return null;
  }

  // ─── Normalization & fuzzy ───

  static String _normalize(String s) {
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

  static bool _fuzzyMatch(String a, String b) {
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

  static int _levenshtein(String a, String b) {
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

/// Result of a database match.
class MatchResult {
  /// Whether the artist was found in the database for this category.
  final bool matched;

  /// The matching artist record (if matched).
  final ArtistRecord? record;

  /// Whether the match is only "probable" (1 source).
  final bool isProbable;

  const MatchResult({
    required this.matched,
    this.record,
    this.isProbable = false,
  });

  @override
  String toString() =>
      'MatchResult(matched: $matched, isProbable: $isProbable, '
      'artist: ${record?.name})';
}
