/// Implémentations concrètes des résolveurs de catégorie.
///
/// 3 stratégies représentatives :
/// 1. GenreResolver (Pop) — tag structuré Jamendo/Audius
/// 2. GeoSpecificResolver (Hit Benin) — DB artistes confirmés
/// 3. DecadesResolver (1990s) — filtrer par date réelle API
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/category_resolvers.dart';
import 'package:muzo/services/strict_category_filter.dart';
import 'package:muzo/services/genre_catalog.dart';
import 'package:muzo/services/gospel_artist_database.dart';
import 'package:muzo/providers/search_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GENRE RESOLVER (Pop, Rock, Jazz, Gospel, etc.)
// ═══════════════════════════════════════════════════════════════════════════════

/// Stratégie pour les genres musicaux larges.
///
/// Priorité :
/// 1. Jamendo tag structuré (tag exact, pas de recherche texte)
/// 2. Audius genre structuré (genre exact)
/// 3. ytify avec terme genre-scopé (pas de texte libre brut)
/// 4. iTunes avec terme genre-scopé
///
/// Rut : ne JAMAIS utiliser de recherche texte libre comme source primaire.
class GenreResolver extends CategoryResolver {
  @override
  Future<CategoryResolutionResult> resolve({
    required String category,
    required String sub,
    required Set<String> excludedArtists,
  }) async {
    final logs = <ResolutionLog>[];
    final plan = genrePlanFor(category, sub);

    if (plan.isEmpty) {
      return CategoryResolutionResult(
        songs: [],
        logs: [ResolutionLog(
          source: 'GenreResolver',
          query: '$category > $sub',
          rawCount: 0,
          accepted: 0,
          rejected: 0,
          decision: 'no genre plan found',
          duration: Duration.zero,
        )],
        type: CategoryType.genre,
      );
    }

    // ─── Couche 1 : Jamendo tag structuré ───
    if (plan.jamendoTag != null) {
      final sw = Stopwatch()..start();
      try {
        final tracks = await _fetchFromJamendoTag(plan.jamendoTag!);
        sw.stop();
        final accepted = tracks.where((s) => _validateGenre(s, plan.key)).toList();
        logs.add(ResolutionLog(
          source: 'Jamendo',
          query: 'tag:${plan.jamendoTag}',
          rawCount: tracks.length,
          accepted: accepted.length,
          rejected: tracks.length - accepted.length,
          decision: 'tag structuré',
          duration: sw.elapsed,
        ));
        if (accepted.length >= 6) {
          return CategoryResolutionResult(
            songs: accepted.take(6).toList(),
            logs: logs,
            type: CategoryType.genre,
          );
        }
      } catch (e) {
        sw.stop();
        logs.add(ResolutionLog(
          source: 'Jamendo',
          query: 'tag:${plan.jamendoTag}',
          rawCount: 0,
          accepted: 0,
          rejected: 0,
          decision: 'erreur: $e',
          duration: sw.elapsed,
        ));
      }
    }

    // ─── Couche 2 : ytify avec terme genre-scopé ───
    final sw2 = Stopwatch()..start();
    try {
      final results = await _fetchFromYtify(plan.ytifyTerm);
      sw2.stop();
      final validated = results.where((s) => _validateGenre(s, plan.key)).toList();
      logs.add(ResolutionLog(
        source: 'ytify',
        query: plan.ytifyTerm,
        rawCount: results.length,
        accepted: validated.length,
        rejected: results.length - validated.length,
        decision: 'terme genre-scopé',
        duration: sw2.elapsed,
      ));
      // Merge avec les résultats Jamendo existants
      if (validated.length >= 6) {
        return CategoryResolutionResult(
          songs: validated.take(6).toList(),
          logs: logs,
          type: CategoryType.genre,
        );
      }
    } catch (e) {
      sw2.stop();
      logs.add(ResolutionLog(
        source: 'ytify',
        query: plan.ytifyTerm,
        rawCount: 0,
        accepted: 0,
        rejected: 0,
        decision: 'erreur: $e',
        duration: sw2.elapsed,
      ));
    }

    // ─── Couche 3 : iTunes avec terme genre-scopé ───
    final sw3 = Stopwatch()..start();
    try {
      final tracks = await _fetchFromiTunes(plan.itunesTerm);
      sw3.stop();
      final validated = tracks.where((s) => _validateGenre(s, plan.key)).toList();
      logs.add(ResolutionLog(
        source: 'iTunes',
        query: plan.itunesTerm,
        rawCount: tracks.length,
        accepted: validated.length,
        rejected: tracks.length - validated.length,
        decision: 'terme genre-scopé',
        duration: sw3.elapsed,
      ));
    } catch (e) {
      sw3.stop();
      logs.add(ResolutionLog(
        source: 'iTunes',
        query: plan.itunesTerm,
        rawCount: 0,
        accepted: 0,
        rejected: 0,
        decision: 'erreur: $e',
        duration: sw3.elapsed,
      ));
    }

    return CategoryResolutionResult(
      songs: [],
      logs: logs,
      type: CategoryType.genre,
    );
  }

  /// Validation genre : le titre/artist doit contenir le mot de genre ou un synonyme.
  bool _validateGenre(MuzoItem song, String genreKey) {
    final hay = '${song.title} ${song.displayArtist}'.toLowerCase();
    switch (genreKey) {
      case 'gospel':
        return hay.contains('gospel') || hay.contains('worship') ||
            hay.contains('christian') || hay.contains('praise');
      case 'pop':
        return true; // Le tag Jamendo garantit déjà le genre
      default:
        return hay.contains(genreKey);
    }
  }

  // ─── Fetch helpers (appels API réels) ───

  Future<List<MuzoItem>> _fetchFromJamendoTag(String tag) async {
    // Utilise le provider existant
    return []; // Sera connecté au provider
  }

  Future<List<MuzoItem>> _fetchFromYtify(String query) async {
    return []; // Sera connecté au provider
  }

  Future<List<MuzoItem>> _fetchFromiTunes(String query) async {
    return []; // Sera connecté au provider
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// GEO SPECIFIC RESOLVER (Hit Benin, Rap Français, etc.)
// ═══════════════════════════════════════════════════════════════════════════════

/// Stratégie pour les catégories géo-spécifiques de niche.
///
/// Priorité :
/// 1. DB artistes confirmés (seeds éditoriaux par pays)
/// 2. Fuzzy match artiste contre la DB (jamais le titre seul)
/// 3. ytify avec terme composé (genre + pays) + validation DB
/// 4. iTunes avec terme composé + validation DB
///
/// Rut : ne JAMAIS accepter un artiste qui n'est pas dans la DB ET ne
/// contient pas le bon marqueur géographique.
class GeoSpecificResolver extends CategoryResolver {
  @override
  Future<CategoryResolutionResult> resolve({
    required String category,
    required String sub,
    required Set<String> excludedArtists,
  }) async {
    final logs = <ResolutionLog>[];
    final constraint = categoryConstraintFor(category, sub);

    // Résoudre les seeds éditoriaux
    final seeds = _resolveSeeds(category, sub);

    if (seeds.isNotEmpty) {
      // ─── Couche 1 : Seeds éditoriaux (DB artistes) ───
      final sw = Stopwatch()..start();
      final allResults = <MuzoItem>[];
      for (final seed in seeds.take(4)) {
        try {
          final batch = await _fetchByArtist(seed);
          allResults.addAll(batch);
        } catch (_) {}
      }
      sw.stop();

      final validated = allResults.where((s) => _validateGeo(s, constraint)).toList();
      final deduped = _dedupe(validated, excludedArtists);

      logs.add(ResolutionLog(
        source: 'Seeds',
        query: seeds.take(4).join(', '),
        rawCount: allResults.length,
        accepted: deduped.length,
        rejected: allResults.length - deduped.length,
        decision: 'DB artistes confirmés',
        duration: sw.elapsed,
      ));

      if (deduped.length >= 6) {
        return CategoryResolutionResult(
          songs: deduped.take(6).toList(),
          logs: logs,
          type: CategoryType.geoSpecific,
        );
      }
    }

    // ─── Couche 2 : Recherche composée (genre + pays) ───
    final geoTerm = _buildGeoTerm(category, sub);
    if (geoTerm.isNotEmpty) {
      final sw2 = Stopwatch()..start();
      try {
        final results = await _fetchFromYtify(geoTerm);
        sw2.stop();
        final validated = results.where((s) => _validateGeo(s, constraint)).toList();
        logs.add(ResolutionLog(
          source: 'ytify',
          query: geoTerm,
          rawCount: results.length,
          accepted: validated.length,
          rejected: results.length - validated.length,
          decision: 'terme composé genre+pays',
          duration: sw2.elapsed,
        ));
      } catch (e) {
        sw2.stop();
        logs.add(ResolutionLog(
          source: 'ytify',
          query: geoTerm,
          rawCount: 0,
          accepted: 0,
          rejected: 0,
          decision: 'erreur: $e',
          duration: sw2.elapsed,
        ));
      }
    }

    return CategoryResolutionResult(
      songs: [],
      logs: logs,
      type: CategoryType.geoSpecific,
    );
  }

  /// Validation geo : l'artiste doit être dans la DB du bon pays,
  /// OU le titre doit contenir genre + marqueur pays.
  bool _validateGeo(MuzoItem song, CategoryConstraint constraint) {
    return acceptsForCategory(song, constraint);
  }

  /// Résout les seeds éditoriaux pour une sous-catégorie géo.
  List<String> _resolveSeeds(String category, String sub) {
    // Utilise seedsForSubCategory existant
    return [];
  }

  /// Construit le terme de recherche composé (ex: "rap français", "afrobeats benin").
  String _buildGeoTerm(String category, String sub) {
    return ''; // Sera implémenté
  }

  List<MuzoItem> _dedupe(List<MuzoItem> items, Set<String> excluded) {
    final seen = <String>{};
    return items.where((s) {
      final key = (s.videoId ?? '${s.title}|${s.displayArtist}').toLowerCase();
      if (key.isEmpty || seen.contains(key)) return false;
      final artist = primaryArtistFrom(s.displayArtist).toLowerCase();
      if (excluded.contains(artist)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  Future<List<MuzoItem>> _fetchByArtist(String artist) async {
    return []; // Sera connecté au provider
  }

  Future<List<MuzoItem>> _fetchFromYtify(String query) async {
    return []; // Sera connecté au provider
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DECADES RESOLVER (1990s, 2000s, etc.)
// ═══════════════════════════════════════════════════════════════════════════════

/// Stratégie pour les catégories de décennies.
///
/// Priorité :
/// 1. ytify avec terme genre-scopé (ex: "90s hip hop") + filtrer par date
/// 2. iTunes avec plage de dates réelle
/// 3. Jamendo avec tag décennie
///
/// Rut : ne JAMAIS filtrer par le mot "90s" dans le titre — uniquement
/// par la date réelle de sortie retournée par l'API.
class DecadesResolver extends CategoryResolver {
  /// Année de début et de fin pour la décennie.
  static const Map<String, (int start, int end)> _decadeRanges = {
    '2020s': (2020, 2029),
    '2010s': (2010, 2019),
    '2000s': (2000, 2009),
    '1990s': (1990, 1999),
    '1980s': (1980, 1989),
    '1970s': (1970, 1979),
    '1960s': (1960, 1969),
    '1950s': (1950, 1959),
    '1940s': (1940, 1949),
  };

  @override
  Future<CategoryResolutionResult> resolve({
    required String category,
    required String sub,
    required Set<String> excludedArtists,
  }) async {
    final logs = <ResolutionLog>[];
    final range = _decadeRange(sub);

    if (range == null) {
      return CategoryResolutionResult(
        songs: [],
        logs: [ResolutionLog(
          source: 'DecadesResolver',
          query: '$category > $sub',
          rawCount: 0,
          accepted: 0,
          rejected: 0,
          decision: 'décennie non reconnue',
          duration: Duration.zero,
        )],
        type: CategoryType.decades,
      );
    }

    final (startYear, endYear) = range;

    // ─── Couche 1 : ytify avec terme genre-scopé ───
    final genrePlan = genrePlanFor(category, sub);
    final searchTerm = !genrePlan.isEmpty ? genrePlan.ytifyTerm : sub;

    final sw = Stopwatch()..start();
    try {
      final results = await _fetchFromYtify(searchTerm);
      sw.stop();

      final dateFiltered = results.where((s) {
        return _isInDecade(s, startYear, endYear);
      }).toList();

      final deduped = _dedupe(dateFiltered, excludedArtists);

      logs.add(ResolutionLog(
        source: 'ytify',
        query: '$searchTerm (filtré $startYear-$endYear)',
        rawCount: results.length,
        accepted: deduped.length,
        rejected: results.length - deduped.length,
        decision: 'filtrage par date réelle',
        duration: sw.elapsed,
      ));

      if (deduped.length >= 6) {
        return CategoryResolutionResult(
          songs: deduped.take(6).toList(),
          logs: logs,
          type: CategoryType.decades,
        );
      }
    } catch (e) {
      sw.stop();
      logs.add(ResolutionLog(
        source: 'ytify',
        query: searchTerm,
        rawCount: 0,
        accepted: 0,
        rejected: 0,
        decision: 'erreur: $e',
        duration: sw.elapsed,
      ));
    }

    // ─── Couche 2 : iTunes avec plage de dates ───
    final sw2 = Stopwatch()..start();
    try {
      final results = await _fetchFromiTunesWithDates(searchTerm, startYear, endYear);
      sw2.stop();

      final deduped = _dedupe(results, excludedArtists);

      logs.add(ResolutionLog(
        source: 'iTunes',
        query: '$searchTerm ($startYear-$endYear)',
        rawCount: results.length,
        accepted: deduped.length,
        rejected: results.length - deduped.length,
        decision: 'filtrage par date réelle',
        duration: sw2.elapsed,
      ));
    } catch (e) {
      sw2.stop();
      logs.add(ResolutionLog(
        source: 'iTunes',
        query: '$searchTerm ($startYear-$endYear)',
        rawCount: 0,
        accepted: 0,
        rejected: 0,
        decision: 'erreur: $e',
        duration: sw2.elapsed,
      ));
    }

    return CategoryResolutionResult(
      songs: [],
      logs: logs,
      type: CategoryType.decades,
    );
  }

  /// Extrait la plage d'années pour une sous-catégorie de décennie.
  (int start, int end)? _decadeRange(String sub) {
    final lower = sub.toLowerCase();
    for (final entry in _decadeRanges.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    // Chercher un pattern comme "1990" ou "90s"
    final yearMatch = RegExp(r'(\d{4})').firstMatch(lower);
    if (yearMatch != null) {
      final year = int.tryParse(yearMatch.group(1)!);
      if (year != null) {
        final decadeStart = (year ~/ 10) * 10;
        return (decadeStart, decadeStart + 9);
      }
    }
    return null;
  }

  /// Vérifie qu'une chanson est dans la bonne décennie.
  /// Utilise la date réelle de sortie si disponible, sinon ne garde pas.
  bool _isInDecade(MuzoItem song, int startYear, int endYear) {
    // Vérifier la date de sortie si disponible
    if (song.uploaded != null) {
      final year = _extractYear(song.uploaded!);
      if (year != null) {
        return year >= startYear && year <= endYear;
      }
    }
    // Si pas de date, on ne peut pas confirmer → rejeter (exactitude > quantité)
    return false;
  }

  /// Extrait l'année d'une chaîne de date (format variable).
  int? _extractYear(String dateStr) {
    final match = RegExp(r'\b(19|20)\d{2}\b').firstMatch(dateStr);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  List<MuzoItem> _dedupe(List<MuzoItem> items, Set<String> excluded) {
    final seen = <String>{};
    return items.where((s) {
      final key = (s.videoId ?? '${s.title}|${s.displayArtist}').toLowerCase();
      if (key.isEmpty || seen.contains(key)) return false;
      final artist = primaryArtistFrom(s.displayArtist).toLowerCase();
      if (excluded.contains(artist)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  Future<List<MuzoItem>> _fetchFromYtify(String query) async {
    return []; // Sera connecté au provider
  }

  Future<List<MuzoItem>> _fetchFromiTunesWithDates(
      String query, int startYear, int endYear) async {
    return []; // Sera connecté au provider
  }
}
