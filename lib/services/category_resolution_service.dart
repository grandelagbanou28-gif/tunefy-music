/// Service de résolution de catégorie qui connecte les résolveurs aux APIs.
///
/// Centralise tous les appels API et les dispatche vers le bon resolver
/// selon le type de catégorie. Gère le logging et le mode debug.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/category_resolvers.dart';
import 'package:muzo/services/strict_category_filter.dart';
import 'package:muzo/services/genre_catalog.dart';
import 'package:muzo/services/gospel_artist_database.dart';
import 'package:muzo/services/indian_content_filter.dart';
import 'package:muzo/services/jamendo_api_service.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/services/youtube_api.dart';
import 'package:muzo/services/piped_api_service.dart';
import 'package:muzo/providers/search_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICE PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════════

/// Service qui résout les sous-catégories en utilisant la stratégie appropriée.
///
/// Utilisation :
/// ```dart
/// final service = CategoryResolutionService(ref);
/// final result = await service.resolve(
///   category: 'Gospel',
///   sub: 'Benin Gospel',
///   excludedArtists: {},
/// );
/// // result.songs → liste de MuzoItem validés
/// // result.logs → logs de chaque source
/// // result.summary → résumé debug humain-readable
/// ```
class CategoryResolutionService {
  final Ref _ref;
  final YoutubeApiService _youtube = YoutubeApiService();

  CategoryResolutionService(this._ref);

  /// Résout une sous-catégorie avec la stratégie appropriée.
  Future<CategoryResolutionResult> resolve({
    required String category,
    required String sub,
    required Set<String> excludedArtists,
  }) async {
    final type = CategoryResolverFactory.typeForSub(category, sub);

    switch (type) {
      case CategoryType.genre:
        return _resolveGenre(category, sub, excludedArtists);
      case CategoryType.geoSpecific:
        return _resolveGeoSpecific(category, sub, excludedArtists);
      case CategoryType.decades:
        return _resolveDecades(category, sub, excludedArtists);
      default:
        return _resolveDefault(category, sub, excludedArtists);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GENRE RESOLVER (Pop, Rock, Jazz, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<CategoryResolutionResult> _resolveGenre(
    String category,
    String sub,
    Set<String> excludedArtists,
  ) async {
    final logs = <ResolutionLog>[];
    final plan = genrePlanFor(category, sub);

    if (plan.isEmpty) {
      return CategoryResolutionResult(
        songs: [],
        logs: _noPlanLog(category, sub),
        type: CategoryType.genre,
      );
    }

    // ─── Couche 1 : Jamendo tag structuré ───
    if (plan.jamendoTag != null) {
      final sw = Stopwatch()..start();
      try {
        final tracks = await _ref
            .read(jamendoApiServiceProvider)
            .tracksByTag(plan.jamendoTag!, limit: 8)
            .timeout(const Duration(seconds: 8));
        sw.stop();
        final items = tracks.map((t) => t.toMuzoItem()).toList();
        final validated = items.where((s) => _validateGenre(s, plan.key)).toList();
        logs.add(ResolutionLog(
          source: 'Jamendo',
          query: 'tag:${plan.jamendoTag}',
          rawCount: items.length,
          accepted: validated.length,
          rejected: items.length - validated.length,
          decision: 'tag structuré',
          duration: sw.elapsed,
        ));
        if (validated.length >= 6) {
          return CategoryResolutionResult(
            songs: validated.take(6).toList(),
            logs: logs,
            type: CategoryType.genre,
          );
        }
      } catch (e) {
        sw.stop();
        logs.add(ResolutionLog(
          source: 'Jamendo', query: 'tag:${plan.jamendoTag}',
          rawCount: 0, accepted: 0, rejected: 0,
          decision: 'erreur: $e', duration: sw.elapsed,
        ));
      }
    }

    // ─── Couche 2 : ytify terme genre-scopé ───
    final sw2 = Stopwatch()..start();
    try {
      final resp = await _ref
          .read(muzoApiServiceProvider)
          .search(plan.ytifyTerm, filter: 'songs')
          .timeout(const Duration(seconds: 10));
      sw2.stop();
      final items = resp.results;
      final validated = items.where((s) => _validateGenre(s, plan.key)).toList();
      logs.add(ResolutionLog(
        source: 'ytify', query: plan.ytifyTerm,
        rawCount: items.length, accepted: validated.length,
        rejected: items.length - validated.length,
        decision: 'terme genre-scopé', duration: sw2.elapsed,
      ));
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
        source: 'ytify', query: plan.ytifyTerm,
        rawCount: 0, accepted: 0, rejected: 0,
        decision: 'erreur: $e', duration: sw2.elapsed,
      ));
    }

    // ─── Couche 3 : Piped terme genre-scopé ───
    final sw3b = Stopwatch()..start();
    try {
      final items = filterIndianContent(await PipedApiService()
          .search(plan.ytifyTerm, filter: 'songs')
          .timeout(const Duration(seconds: 10)));
      sw3b.stop();
      final validated = items.where((s) => _validateGenre(s, plan.key)).toList();
      logs.add(ResolutionLog(
        source: 'Piped', query: plan.ytifyTerm,
        rawCount: items.length, accepted: validated.length,
        rejected: items.length - validated.length,
        decision: 'terme genre-scopé', duration: sw3b.elapsed,
      ));
      if (validated.length >= 6) {
        return CategoryResolutionResult(
          songs: validated.take(6).toList(),
          logs: logs,
          type: CategoryType.genre,
        );
      }
    } catch (e) {
      sw3b.stop();
      logs.add(ResolutionLog(
        source: 'Piped', query: plan.ytifyTerm,
        rawCount: 0, accepted: 0, rejected: 0,
        decision: 'erreur: $e', duration: sw3b.elapsed,
      ));
    }

    // ─── Couche 4 : iTunes terme genre-scopé ───
    final sw3 = Stopwatch()..start();
    try {
      final tracks = await _ref
          .read(itunesApiServiceProvider)
          .searchSongsFrUs(plan.itunesTerm, limit: 8)
          .timeout(const Duration(seconds: 9));
      sw3.stop();
      final validated = tracks.where((s) => _validateGenre(s, plan.key)).toList();
      logs.add(ResolutionLog(
        source: 'iTunes', query: plan.itunesTerm,
        rawCount: tracks.length, accepted: validated.length,
        rejected: tracks.length - validated.length,
        decision: 'terme genre-scopé', duration: sw3.elapsed,
      ));
    } catch (e) {
      sw3.stop();
      logs.add(ResolutionLog(
        source: 'iTunes', query: plan.itunesTerm,
        rawCount: 0, accepted: 0, rejected: 0,
        decision: 'erreur: $e', duration: sw3.elapsed,
      ));
    }

    return CategoryResolutionResult(songs: [], logs: logs, type: CategoryType.genre);
  }

  bool _validateGenre(MuzoItem song, String genreKey) {
    final hay = '${song.title} ${song.displayArtist}'.toLowerCase();
    switch (genreKey) {
      case 'gospel':
        return hay.contains('gospel') || hay.contains('worship') ||
            hay.contains('christian') || hay.contains('praise');
      case 'pop':
        return true; // Tag Jamendo garantit déjà le genre
      default:
        return hay.contains(genreKey);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GEO SPECIFIC RESOLVER (Hit Benin, Rap Français, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<CategoryResolutionResult> _resolveGeoSpecific(
    String category,
    String sub,
    Set<String> excludedArtists,
  ) async {
    final logs = <ResolutionLog>[];
    final constraint = categoryConstraintFor(category, sub);
    final seeds = seedsForSubCategory(category, sub);

    // ─── Couche 1 : Seeds éditoriaux (DB artistes confirmés) ───
    if (seeds.isNotEmpty) {
      final sw = Stopwatch()..start();
      final allResults = <MuzoItem>[];
      for (final seed in seeds.take(4)) {
        try {
          final batch = await _fetchArtist(seed);
          allResults.addAll(batch);
        } catch (_) {}
      }
      sw.stop();

      final validated = allResults
          .where((s) => acceptsForCategory(s, constraint))
          .toList();
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
    final geoTerm = buildScopedSearchTerm(category, sub, '');
    if (geoTerm.isNotEmpty) {
      final sw2 = Stopwatch()..start();
      try {
        final resp = await _ref
            .read(muzoApiServiceProvider)
            .search(geoTerm, filter: 'songs')
            .timeout(const Duration(seconds: 12));
        sw2.stop();
        final items = resp.results;
        final validated = items
            .where((s) => acceptsForCategory(s, constraint))
            .toList();
        logs.add(ResolutionLog(
          source: 'ytify', query: geoTerm,
          rawCount: items.length, accepted: validated.length,
          rejected: items.length - validated.length,
          decision: 'terme composé genre+pays', duration: sw2.elapsed,
        ));
        if (validated.length >= 6) {
          return CategoryResolutionResult(
            songs: validated.take(6).toList(),
            logs: logs,
            type: CategoryType.geoSpecific,
          );
        }
      } catch (e) {
        sw2.stop();
        logs.add(ResolutionLog(
          source: 'ytify', query: geoTerm,
          rawCount: 0, accepted: 0, rejected: 0,
          decision: 'erreur: $e', duration: sw2.elapsed,
        ));
      }

      // ─── Couche 3 : Piped terme composé ───
      final sw2b = Stopwatch()..start();
      try {
        final items = await PipedApiService()
            .search(geoTerm, filter: 'songs')
            .timeout(const Duration(seconds: 10));
        sw2b.stop();
        final validated = items
            .where((s) => acceptsForCategory(s, constraint))
            .where((s) => !isIndianContent(s))
            .toList();
        logs.add(ResolutionLog(
          source: 'Piped', query: geoTerm,
          rawCount: items.length, accepted: validated.length,
          rejected: items.length - validated.length,
          decision: 'terme composé genre+pays', duration: sw2b.elapsed,
        ));
        if (validated.length >= 6) {
          return CategoryResolutionResult(
            songs: validated.take(6).toList(),
            logs: logs,
            type: CategoryType.geoSpecific,
          );
        }
      } catch (e) {
        sw2b.stop();
        logs.add(ResolutionLog(
          source: 'Piped', query: geoTerm,
          rawCount: 0, accepted: 0, rejected: 0,
          decision: 'erreur: $e', duration: sw2b.elapsed,
        ));
      }

      // ─── Couche 4 : iTunes terme composé ───
      final sw3 = Stopwatch()..start();
      try {
        final tracks = await _ref
            .read(itunesApiServiceProvider)
            .searchSongsFrUs(geoTerm, limit: 8)
            .timeout(const Duration(seconds: 12));
        sw3.stop();
        final validated = tracks
            .where((s) => acceptsForCategory(s, constraint))
            .toList();
        logs.add(ResolutionLog(
          source: 'iTunes', query: geoTerm,
          rawCount: tracks.length, accepted: validated.length,
          rejected: tracks.length - validated.length,
          decision: 'terme composé genre+pays', duration: sw3.elapsed,
        ));
      } catch (e) {
        sw3.stop();
        logs.add(ResolutionLog(
          source: 'iTunes', query: geoTerm,
          rawCount: 0, accepted: 0, rejected: 0,
          decision: 'erreur: $e', duration: sw3.elapsed,
        ));
      }
    }

    // ─── Couche 4 : YouTube (Gospel sub-categories) ───
    final sw4 = Stopwatch()..start();
    try {
      final ytResults = await _youtube.search(query: sub, maxResults: 10);
      sw4.stop();
      // youtube_api.dart retourne des Maps brutes → conversion MuzoItem
      final ytItems = ytResults
          .whereType<Map>()
          .map((m) => MuzoItem(
                title: (m['title'] ?? 'Unknown').toString(),
                videoId: m['id']?.toString(),
                isExplicit: false,
                thumbnails: [
                  if (m['thumbnail'] != null)
                    MuzoThumbnail(
                        url: m['thumbnail'].toString(), width: 0, height: 0),
                ],
                channelName: m['channel']?.toString(),
                artists: [
                  MuzoArtist(
                      name: m['channel']?.toString() ?? 'Unknown', id: ''),
                ],
                resultType: 'song',
              ))
          .toList();
      final validated = ytItems
          .where((s) => acceptsForCategory(s, constraint))
          .where((s) => !isIndianContent(s))
          .toList();
      logs.add(ResolutionLog(
        source: 'YouTube', query: sub,
        rawCount: ytResults.length, accepted: validated.length,
        rejected: ytResults.length - validated.length,
        decision: 'YouTube — sous-cat Gospel', duration: sw4.elapsed,
      ));
      if (validated.length >= 6) {
        return CategoryResolutionResult(
          songs: validated.take(6).toList(),
          logs: logs,
          type: CategoryType.geoSpecific,
        );
      }
    } catch (e) {
      sw4.stop();
      logs.add(ResolutionLog(
        source: 'YouTube', query: sub,
        rawCount: 0, accepted: 0, rejected: 0,
        decision: 'erreur: $e', duration: sw4.elapsed,
      ));
    }

    return CategoryResolutionResult(
      songs: [], logs: logs, type: CategoryType.geoSpecific,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DECADES RESOLVER (1990s, 2000s, etc.)
  // ═══════════════════════════════════════════════════════════════════════════

  static const Map<String, (int start, int end)> _decadeRanges = {
    '2020s': (2020, 2029), '2010s': (2010, 2019),
    '2000s': (2000, 2009), '1990s': (1990, 1999),
    '1980s': (1980, 1989), '1970s': (1970, 1979),
    '1960s': (1960, 1969), '1950s': (1950, 1959),
  };

  Future<CategoryResolutionResult> _resolveDecades(
    String category,
    String sub,
    Set<String> excludedArtists,
  ) async {
    final logs = <ResolutionLog>[];
    final range = _decadeRange(sub);

    if (range == null) {
      return CategoryResolutionResult(
        songs: [],
        logs: [ResolutionLog(
          source: 'DecadesResolver', query: '$category > $sub',
          rawCount: 0, accepted: 0, rejected: 0,
          decision: 'décennie non reconnue', duration: Duration.zero,
        )],
        type: CategoryType.decades,
      );
    }

    final (startYear, endYear) = range;
    final plan = genrePlanFor(category, sub);
    final searchTerm = !plan.isEmpty ? plan.ytifyTerm : sub;

    // ─── Couche 1 : ytify terme genre-scopé + filtrage date ───
    final sw = Stopwatch()..start();
    try {
      final resp = await _ref
          .read(muzoApiServiceProvider)
          .search(searchTerm, filter: 'songs')
          .timeout(const Duration(seconds: 10));
      sw.stop();
      final items = resp.results;
      final dateFiltered = items
          .where((s) => _isInDecade(s, startYear, endYear))
          .toList();
      final deduped = _dedupe(dateFiltered, excludedArtists);

      logs.add(ResolutionLog(
        source: 'ytify', query: '$searchTerm (filtré $startYear-$endYear)',
        rawCount: items.length, accepted: deduped.length,
        rejected: items.length - deduped.length,
        decision: 'filtrage par date réelle', duration: sw.elapsed,
      ));

      if (deduped.length >= 6) {
        return CategoryResolutionResult(
          songs: deduped.take(6).toList(), logs: logs,
          type: CategoryType.decades,
        );
      }
    } catch (e) {
      sw.stop();
      logs.add(ResolutionLog(
        source: 'ytify', query: searchTerm,
        rawCount: 0, accepted: 0, rejected: 0,
        decision: 'erreur: $e', duration: sw.elapsed,
      ));
    }

    // ─── Couche 2 : iTunes terme genre-scopé + filtrage date ───
    final sw2 = Stopwatch()..start();
    try {
      final tracks = await _ref
          .read(itunesApiServiceProvider)
          .searchSongsFrUs(searchTerm, limit: 12)
          .timeout(const Duration(seconds: 9));
      sw2.stop();
      final dateFiltered = tracks
          .where((s) => _isInDecade(s, startYear, endYear))
          .toList();
      final deduped = _dedupe(dateFiltered, excludedArtists);

      logs.add(ResolutionLog(
        source: 'iTunes', query: '$searchTerm ($startYear-$endYear)',
        rawCount: tracks.length, accepted: deduped.length,
        rejected: tracks.length - deduped.length,
        decision: 'filtrage par date réelle', duration: sw2.elapsed,
      ));
    } catch (e) {
      sw2.stop();
      logs.add(ResolutionLog(
        source: 'iTunes', query: '$searchTerm ($startYear-$endYear)',
        rawCount: 0, accepted: 0, rejected: 0,
        decision: 'erreur: $e', duration: sw2.elapsed,
      ));
    }

    return CategoryResolutionResult(
      songs: [], logs: logs, type: CategoryType.decades,
    );
  }

  (int start, int end)? _decadeRange(String sub) {
    final lower = sub.toLowerCase();
    for (final entry in _decadeRanges.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
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

  bool _isInDecade(MuzoItem song, int startYear, int endYear) {
    if (song.uploaded != null) {
      final year = _extractYear(song.uploaded!);
      if (year != null) return year >= startYear && year <= endYear;
    }
    // Pas de date → rejeter (exactitude > quantité)
    return false;
  }

  int? _extractYear(String dateStr) {
    final match = RegExp(r'\b(19|20)\d{2}\b').firstMatch(dateStr);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEFAULT RESOLVER (fallback)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<CategoryResolutionResult> _resolveDefault(
    String category,
    String sub,
    Set<String> excludedArtists,
  ) async {
    // Fallback : utiliser l'ancien pipeline
    return CategoryResolutionResult(
      songs: [], logs: [ResolutionLog(
        source: 'DefaultResolver', query: '$category > $sub',
        rawCount: 0, accepted: 0, rejected: 0,
        decision: 'fallback → ancien pipeline', duration: Duration.zero,
      )], type: CategoryType.fallback,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<MuzoItem>> _fetchArtist(String artist) async {
    final q = primaryArtistName(artist);
    if (q.isEmpty) return [];
    try {
      final resp = await _ref
          .read(muzoApiServiceProvider)
          .search(q, filter: 'songs')
          .timeout(const Duration(seconds: 10));
      return resp.results;
    } catch (_) {
      return [];
    }
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

  List<ResolutionLog> _noPlanLog(String category, String sub) {
    return [ResolutionLog(
      source: 'Resolver', query: '$category > $sub',
      rawCount: 0, accepted: 0, rejected: 0,
      decision: 'aucun plan trouvé', duration: Duration.zero,
    )];
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGGING DEBUG
// ═══════════════════════════════════════════════════════════════════════════════

/// Flag global pour activer/désactiver les logs de résolution.
bool debugCategoryResolution = false;

/// Affiche les logs de résolution dans la console debug.
void logResolution(CategoryResolutionResult result) {
  if (!debugCategoryResolution) return;
  debugPrint(result.summary);
}
