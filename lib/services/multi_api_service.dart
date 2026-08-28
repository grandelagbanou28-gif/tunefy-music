import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/musicbrainz_service.dart';
import 'package:muzo/services/spotify_unofficial_service.dart';
import 'package:muzo/services/itunes_api_service.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/services/storage_service.dart';

final multiApiServiceProvider = Provider<MultiApiService>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return MultiApiService(storage);
});

/// Aggregator that queries WORKING keyless APIs in parallel to DISCOVER
/// extra song titles the YouTube backend search missed. Discovery is
/// metadata-only; callers resolve titles to playable YouTube tracks via
/// [resolveToPlayable].
class MultiApiService {
  final StorageService _storage;
  MultiApiService(this._storage);

  MusicBrainzService? _musicBrainz;
  SpotifyUnofficialService? _spotify;
  MuzoApiService? _api;

  MusicBrainzService get musicBrainz => _musicBrainz ??= MusicBrainzService();
  SpotifyUnofficialService get spotify => _spotify ??= SpotifyUnofficialService();
  MuzoApiService get api => _api ??= MuzoApiService(_storage);

  /// Discover song titles across working APIs in parallel.
  /// Never throws — each failing source returns []. Returned items may lack
  /// a [MuzoItem.videoId]; they are discovery entries only.
  Future<List<MuzoItem>> discover(String query) async {
    final futures = <Future<List<MuzoItem>>>[
      _safe(() => musicBrainz.searchTracks(query), 'MusicBrainz'),
      _safe(() => spotify.search(query), 'Spotify'),
      _safe(() => ItunesApiService().searchSongsFrUs(query, limit: 10),
          'iTunes'),
    ];

    final results = await Future.wait(futures, eagerError: false);
    final seen = <String>{};
    final merged = <MuzoItem>[];
    for (final batch in results) {
      for (final item in batch) {
        final key = item.title.toLowerCase().trim();
        if (item.title.isEmpty) continue;
        if (seen.add(key)) merged.add(item);
      }
    }
    debugPrint(
        'MultiApi.discover: "$query" -> ${merged.length} titles '
        '(${futures.length} sources)');
    return merged;
  }

  /// Resolve discovered titles to real, playable YouTube tracks using the
  /// main ytify search. Bounded to [max] resolutions, run in parallel,
  /// deduplicated by videoId. Returns only playable items.
  Future<List<MuzoItem>> resolveToPlayable(
    List<MuzoItem> discovered, {
    int max = 8,
  }) async {
    final futures = <Future<List<MuzoItem>>>[];
    for (final item in discovered.take(max)) {
      final q = item.title.trim();
      if (q.isEmpty) continue;
      futures.add(() async {
        try {
          final resp = await api.search(q, filter: 'songs');
          final results = resp.results
              .where((r) => r.videoId != null)
              .toList();
          if (results.isEmpty) return <MuzoItem>[];
          final best = results.first;
          final existing = results.indexWhere(
            (r) => r.title.toLowerCase() == q.toLowerCase(),
          );
          return [existing >= 0 ? results[existing] : best];
        } catch (e) {
          debugPrint('MultiApi.resolve error for "$q": $e');
          return <MuzoItem>[];
        }
      }());
    }

    final batches = await Future.wait(futures, eagerError: false);
    final seenIds = <String>{};
    final playable = <MuzoItem>[];
    for (final batch in batches) {
      for (final item in batch) {
        if (item.videoId != null && seenIds.add(item.videoId!)) {
          playable.add(item);
        }
      }
    }
    debugPrint('MultiApi.resolveToPlayable: ${playable.length} playable');
    return playable;
  }

  Future<List<MuzoItem>> _safe(
    Future<List<MuzoItem>> Function() fn,
    String source,
  ) async {
    try {
      return await fn();
    } catch (e) {
      debugPrint('MultiApi[$source] error: $e');
      return [];
    }
  }
}