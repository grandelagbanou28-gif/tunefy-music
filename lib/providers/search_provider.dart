import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/audius_api_service.dart';
import 'package:muzo/services/category_curator.dart';
import 'package:muzo/services/genre_catalog.dart';
import 'package:muzo/services/sub_category_seeds.dart';
import 'package:muzo/services/jamendo_api_service.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/services/strict_category_filter.dart';
import 'package:muzo/services/category_resolution_service.dart';
import 'package:muzo/services/category_resolvers.dart';
import 'package:muzo/services/content_cache_service.dart';
import 'package:muzo/services/itunes_api_service.dart';
import 'package:muzo/services/trending_service.dart';
import 'package:muzo/services/multi_api_service.dart';

final searchControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final searchFocusNodeProvider = Provider<FocusNode>((ref) {
  final focusNode = FocusNode();
  ref.onDispose(() => focusNode.dispose());
  return focusNode;
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchFilterProvider = StateProvider<String>((ref) => 'all');

final searchResultsProvider =
    StateNotifierProvider<SearchResultsNotifier, AsyncValue<List<MuzoItem>>>(
      (ref) {
        return SearchResultsNotifier(ref);
      },
    );


class SearchResultsNotifier
    extends StateNotifier<AsyncValue<List<MuzoItem>>> {
  final Ref ref;



  late final MuzoApiService _api = ref.read(muzoApiServiceProvider);
  String? _continuationToken;
  bool _isLoadingMore = false;

  SearchResultsNotifier(this.ref) : super(const AsyncValue.data([])) {
    // Listen to query and filter changes
    ref.listen(searchQueryProvider, (previous, next) {
      if (next.isNotEmpty) {
        _search(next, ref.read(searchFilterProvider));
      } else {
        state = const AsyncValue.data([]);
      }
    });
    ref.listen(searchFilterProvider, (previous, next) {
      final query = ref.read(searchQueryProvider);
      if (query.isNotEmpty) _search(query, next);
    });
  }

  Future<void> _search(String query, String filter) async {
    state = const AsyncValue.loading();
    _continuationToken = null;
    try {
      if (filter == 'all') {
        final futures = [
          _api.search(query, filter: 'songs').then((res) => res.results.map((r) => r.copyWith(category: 'Songs')).toList()),
          _api.search(query, filter: 'videos').then((res) => res.results.map((r) => r.copyWith(category: 'Videos')).toList()),
          _api.search(query, filter: 'albums').then((res) => res.results.map((r) => r.copyWith(category: 'Albums')).toList()),
          _api.search(query, filter: 'artists').then((res) => res.results.map((r) => r.copyWith(category: 'Artists')).toList()),
          _api.search(query, filter: 'playlists').then((res) => res.results.map((r) => r.copyWith(category: 'Playlists')).toList()),
          _api.search(query, filter: 'channels').then((res) => res.results.map((r) => r.copyWith(category: 'Channels')).toList()),
          ref.read(itunesApiServiceProvider).searchPodcastEpisodesFrUs(query, limit: 8).then((res) => res.map((r) => r.copyWith(category: 'Podcasts')).toList()),
        ];
        final resultsArray = await Future.wait(futures);
        _continuationToken = null;
        var merged = _prioritizeWestern(
          resultsArray.expand((i) => i).toList(),
        );

        // When the YouTube backend is thin, discover extra titles from the
        // working keyless APIs (MusicBrainz / Spotify / iTunes) and
        // resolve them to playable YouTube tracks.
        if (merged.length < 20 && query.trim().isNotEmpty) {
          try {
            final multi = ref.read(multiApiServiceProvider);
            final discovered = await multi.discover(query);
            final playable = await multi.resolveToPlayable(discovered);
            final known = merged
                .map((r) => r.title.toLowerCase().trim())
                .toSet();
            for (final p in playable) {
              final key = p.title.toLowerCase().trim();
              if (known.add(key) && p.videoId != null) {
                merged = [...merged, p];
              }
            }
          } catch (e) {
            debugPrint('MultiApi search enrichment failed: $e');
          }
        }

        state = AsyncValue.data(merged);
      } else {
        final response = await _api.search(query, filter: filter);
        _continuationToken = response.continuationToken;
        state = AsyncValue.data(_prioritizeWestern(response.results));
      }
      state = AsyncValue.data(_dedupeSongs(state.value ?? []));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_continuationToken == null || _isLoadingMore) return;

    _isLoadingMore = true;
    final currentResults = state.value ?? [];
    final query = ref.read(searchQueryProvider);
    final filter = ref.read(searchFilterProvider);

    try {
      final response = await _api.search(
        query,
        filter: filter,
        continuationToken: _continuationToken,
      );
      _continuationToken = response.continuationToken;
      state = AsyncValue.data(_dedupeSongs([...currentResults, ...response.results]));
    } catch (e) {
      debugPrint('Error loading more search results: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  bool get hasMore => _continuationToken != null;
}

final searchSuggestionsProvider = FutureProvider.family<List<String>, String>((
  ref,
  query,
) async {
  if (query.isEmpty) return [];
  final apiService = ref.read(muzoApiServiceProvider);
  return await apiService.getSearchSuggestions(query);
});

/// Real songs for a Search "Browse All" category.
///
/// Genre-first engine (keyless multi-source):
///   * If the query resolves to a [GenrePlan], the section is filled with real
///     genre-exact content: Jamendo genre tag + Audius trending-by-genre
///     (both directly playable, both exactly on genre) + a ytify search
///     scoped to the genre word + iTunes metadata for that genre. There is
///     NO generic "hits / trending / top songs" fallback any more — that's
///     what used to drop Bachata / Arabic Kuthu into Gospel sections.
///   * If the query is a seed artist name (no genre plan), we keep the
///     artist-scoped path (Jamendo exact-artist, ytify artist songs, iTunes)
///     which is already genre-correct because the seeds are editorial.
/// All queries bounded, junk-filtered, deduplicated and capped.
final categorySongsProvider =
    FutureProvider.family<List<MuzoItem>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final apiService = ref.read(muzoApiServiceProvider);
  final jamendo = ref.read(jamendoApiServiceProvider);

  final plan = genrePlanFor(query, query);
  final ambient = isAmbientQuery(query) || plan.ambient;

  final seen = <String>{};
  final songs = <MuzoItem>[];

  void addBatch(List<MuzoItem> batch, {bool genreExact = false}) {
    for (final song in batch) {
      if (!isActuallyPlayable(song)) continue;
      if (isJunkSong(song.title, isAmbient: ambient)) continue;
      final key =
          (song.videoId ?? '${song.title}|${song.displayArtist}').toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      if (!genreExact && !plan.isEmpty) {
        if (_conflictsGenre(song, plan)) continue;
      }
      seen.add(key);
      songs.add(song);
    }
  }

  // ─── Genre-driven section: source genre-exact music in parallel ───
  if (!plan.isEmpty) {
    // Fast layer: Jamendo tag + Audius genre — direct full audio, exact genre.
    final fast = <Future<List<MuzoItem>>>[
      if (plan.jamendoTag != null)
        jamendo
            .tracksByTag(plan.jamendoTag!, limit: 8)
            .then((t) => t.map((t2) => t2.toMuzoItem()).toList())
            .timeout(const Duration(seconds: 8), onTimeout: () => const []),
      for (final g in plan.audiusGenres)
        ref
            .read(audiusApiServiceProvider)
            .tracksByGenre(g, limit: 8)
            .then((t) => t.map((t2) => t2.toMuzoItem()).toList())
            .timeout(const Duration(seconds: 8), onTimeout: () => const []),
    ];
    for (final batch in await Future.wait(fast)) {
      addBatch(batch, genreExact: true);
    }

    // Top-up layer: ytify scoped to the genre word. Music is served by
    // muzoapi (YouTube) exclusively — iTunes song previews (30s clips) are
    // intentionally excluded from every music pipeline.
    if (songs.length < 10) {
      final topups = <Future<List<MuzoItem>>>[
        apiService
            .search(plan.ytifyTerm, filter: 'songs')
            .then((res) => _prioritizeWestern(res.results))
            .timeout(const Duration(seconds: 10), onTimeout: () => const []),
      ];
      for (final batch in await Future.wait(topups)) {
        addBatch(batch);
      }
    }

    // Last resort, still genre-scoped: re-run the ytify genre search once.
    if (songs.isEmpty) {
      try {
        final resp = await apiService
            .search(plan.ytifyTerm, filter: 'songs')
            .timeout(const Duration(seconds: 10));
        addBatch(_prioritizeWestern(resp.results));
      } catch (_) {}
    }
    return songs.take(15).toList();
  }

  // ─── Artist-driven section: a seed artist name — keep artist-scoped path ──
  final seeds = seedsFor(query);
  final sourceQueries = seeds.isNotEmpty
      ? seeds.take(5).toList()
      : <String>[query];

  Future<List<MuzoItem>> jamendoBatch(String q) async {
    final ql = q.trim().toLowerCase();
    List<JamendoTrack> tracks;
    final tag = jamendoTagFor(q);
    if (tag != null) {
      try {
        tracks = await jamendo.tracksByTag(tag, limit: 8).timeout(
              const Duration(seconds: 8),
            );
      } catch (_) {
        tracks = [];
      }
    } else {
      try {
        tracks = await jamendo.searchTracks(q, limit: 10).timeout(
              const Duration(seconds: 8),
            );
        tracks = tracks
            .where((t) =>
                t.artistName.toLowerCase().contains(ql) ||
                (t.artistName.isNotEmpty &&
                    ql.contains(t.artistName.toLowerCase())))
            .take(8)
            .toList();
      } catch (_) {
        tracks = [];
      }
    }
    return tracks.map((t) => t.toMuzoItem()).toList();
  }

  await Future.wait(sourceQueries.map((q) async {
    List<MuzoItem> batch = await jamendoBatch(q);
    if (batch.isEmpty) {
      try {
        final resp = await apiService
            .search(q, filter: 'songs')
            .timeout(const Duration(seconds: 10));
        batch = _prioritizeWestern(resp.results);
      } catch (_) {
        batch = [];
      }
    }
    addBatch(batch);
  }).toList());

  return songs.take(15).toList();
});

/// Loose conformance guard for ytify/iTunes results in a genre section: only
/// reject a song when its title/artist *explicitly* names a conflicting genre
/// far from the section's (e.g. an "Arabic Kuthu" video surfacing inside a
/// Gospel search would be dropped because it advertises Bollywood/Tamil).
/// Otherwise we keep it — a seed artist like "Kirk Franklin" legitimately
/// never says "gospel" in the title.
bool _conflictsGenre(MuzoItem song, GenrePlan plan) {
  final hay = '${song.title} ${song.displayArtist}'.toLowerCase();
  if (_strongPositiveGenreMatch(hay, plan.key)) return false;
  final conflicts = _genreConflictMarkers[plan.key];
  if (conflicts == null) return false;
  return conflicts.any(hay.contains);
}

const Map<String, Set<String>> _genreConflictMarkers = {
  'gospel': {
    'bollywood', 'tamil', 'punjabi', 'arabic', 'kuthu', 'hindi',
  },
  'gospel hits': {
    'bollywood', 'tamil', 'punjabi', 'arabic', 'kuthu', 'hindi',
  },
  'contemporary gospel': {
    'bollywood', 'tamil', 'punjabi', 'arabic', 'kuthu', 'hindi',
  },
  'salsa': {'reggaeton', 'bachata', 'cumbia', 'bollywood'},
  'bachata': {'reggaeton', 'salsa', 'cumbia', 'bollywood'},
  'reggaeton': {'salsa', 'bollywood', 'kuthu'},
  'classical': {'bollywood', 'rave', 'techno', 'edm'},
  'jazz': {'bollywood', 'edm', 'techno'},
  'country': {'bollywood', 'kuthu', 'punjabi'},
  'amapiano': {'bollywood', 'arabic', 'kuthu'},
  'kpop': {'bollywood', 'arabic', 'kuthu', 'tamil'},
};

/// True when the song explicitly belongs to the section genre: the genre word
/// (or its near synonyms) appears in title/artist. Used to accept a result even
/// when a stray conflict marker also appears.
bool _strongPositiveGenreMatch(String hay, String key) {
  switch (key) {
    case 'gospel':
    case 'gospel hits':
    case 'contemporary gospel':
      return hay.contains('gospel') ||
          hay.contains('worship') ||
          hay.contains('christian');
    case 'hip hop':
    case 'rap':
      return hay.contains('rap') || hay.contains('hip hop');
    case 'r&b':
      return hay.contains('rnb') || hay.contains('r&b');
    default:
      final kw = key
          .replaceAll('&', ' ')
          .replaceAll('-', ' ')
          .replaceAll('  ', ' ')
          .trim();
      return hay.contains(kw);
  }
}

/// True when a sub-section is ambient / spoken-word / long-form content where
/// the junk filter must stay off (Sleep Music, Deep Focus, Rain, ASMR...).
bool isAmbientSubCategory(String category, String sub) {
  if (isAmbientQuery(category) || isAmbientQuery(sub)) return true;
  final l = sub.toLowerCase();
  final ambientSubs = {
    'sleep music',
    'deep sleep',
    'white noise',
    'brown noise',
    'nature sounds',
    'rain',
    'ocean',
    'asmr',
    'meditation',
    'guided meditation',
    'breathing',
    'yoga',
    'sleep stories',
    'baby sleep',
    'whispers',
    'scary stories',
  };
  return ambientSubs.contains(l) ||
      l.contains('sleep') ||
      l.contains('meditation') ||
      l.contains('white noise') ||
      l.contains('asmr') ||
      l.contains('rain') ||
      l.contains('shadowing') ||
      l.contains('english') ||
      l.contains('pronunciation');
}

/// Editorial seed artists for a specific sub-category. Walks three levels:
/// 1. Sub-category-specific seeds (e.g. Marc Anthony for "Salsa").
/// 2. Parent category seeds (from category_curator.dart) as fallback.
/// Always returns at most 6 artists to bound backend round-trips.
List<String> seedsForSubCategory(String category, String sub) {
  final specific = subCategorySeeds(category, sub);
  if (specific != null && specific.isNotEmpty) return specific.take(6).toList();
  final parent = seedsFor(category);
  if (parent.isNotEmpty) return parent.take(6).toList();
  return const [];
}

/// Composite search term for a term-driven sub-category that has no dedicated
/// artist seeds. Combines the sub-category name with the parent genre so the
/// backend returns on-topic results (e.g. "Salsa" + "Latin" -> "salsa latin").
String queryForSubCategory(String category, String sub) {
  final subLower = sub.trim().toLowerCase();
  final catLower = category.trim().toLowerCase();
  if (subLower == catLower || subLower.contains(catLower)) {
    return sub.trim();
  }
  return '${sub.trim()} $category';
}

/// Per-sub-category editorial tuning for structural subs (Music category and
/// beyond). Each flag changes how candidate songs are filtered / ranked so a
/// section actually behaves like its name instead of being a generic list.
class _SubTuning {
  const _SubTuning({
    this.rejectOld = false,
    this.sortByViews = false,
    this.singlesOnly = false,
    this.albumTracksOnly = false,
  });

  /// Drop uploads older than ~1 year ("x years ago") and rank fresher first.
  final bool rejectOld;

  /// Rank most-viewed first (popularity proxy).
  final bool sortByViews;

  /// Keep single releases only: short tracks whose album is absent or named
  /// after the song (YouTube Music convention for singles).
  final bool singlesOnly;

  /// Keep album cuts only: track must carry an album distinct from its title.
  final bool albumTracksOnly;

  bool get isActive =>
      rejectOld || sortByViews || singlesOnly || albumTracksOnly;
}

/// Strategy table — extend as more structural subs are curated.
_SubTuning _tuningForSub(String sub) {
  switch (sub.trim().toLowerCase()) {
    case 'new music':
      return const _SubTuning(rejectOld: true);
    case 'trending':
      return const _SubTuning(rejectOld: true, sortByViews: true);
    case 'popular':
    case 'top songs':
    case 'music videos':
    case 'compilations':
      return const _SubTuning(sortByViews: true);
    case 'top albums':
    case 'albums':
      return const _SubTuning(albumTracksOnly: true, sortByViews: true);
    case 'singles':
      return const _SubTuning(singlesOnly: true, sortByViews: true);
    default:
      return const _SubTuning();
  }
}

/// Numeric view count from labels like "1,234,567 views" (0 when unknown).
int _viewsCount(MuzoItem s) => int.tryParse(
      (s.views ?? '').replaceAll(RegExp(r'[^0-9]'), ''),
    ) ??
    0;

/// Upload age bucket — lower is fresher; unknown uploads rank worst (99).
int _uploadFreshness(String? uploaded) {
  if (uploaded == null || uploaded.isEmpty) return 99;
  final l = uploaded.toLowerCase();
  final n = int.tryParse(l.split(' ').first) ?? 99;
  if (l.contains('hour')) return n;
  if (l.contains('day')) return 10 + n;
  if (l.contains('week')) return 100 + n;
  if (l.contains('month')) return 1000 + n;
  if (l.contains('year')) return 10000 + n;
  return 99;
}

bool _isOldUpload(MuzoItem s) =>
    (s.uploaded ?? '').toLowerCase().contains('year');

bool _normStartsWith(String a, String b) =>
    a.startsWith(b) || b.startsWith(a);

/// Single release: short track, no album or album named after the song.
bool _looksLikeSingle(MuzoItem s) {
  final dur = s.durationSeconds;
  if (dur != null && dur > 360) return false;
  final album = s.album?.name.trim().toLowerCase() ?? '';
  if (album.isEmpty) return true;
  final title = s.title.trim().toLowerCase();
  return album == title || _normStartsWith(title, album);
}

/// Album cut: carries an album clearly distinct from the song title.
bool _looksLikeAlbumTrack(MuzoItem s) {
  final album = s.album?.name.trim().toLowerCase() ?? '';
  if (album.isEmpty) return false;
  final title = s.title.trim().toLowerCase();
  return album != title && !_normStartsWith(title, album);
}

/// Applies the sub-category strategy to a raw candidate batch: filters by
/// shape (singles / album cuts / freshness) then ranks (views or freshness).
List<MuzoItem> _tuneBatchForSub(String sub, List<MuzoItem> batch) {
  final t = _tuningForSub(sub);
  if (!t.isActive) return batch;
  var out = batch.where((s) {
    if (t.rejectOld && _isOldUpload(s)) return false;
    if (t.singlesOnly && !_looksLikeSingle(s)) return false;
    if (t.albumTracksOnly && !_looksLikeAlbumTrack(s)) return false;
    return true;
  }).toList();
  if (t.sortByViews) {
    out.sort((a, b) => _viewsCount(b).compareTo(_viewsCount(a)));
  } else if (t.rejectOld) {
    out.sort((a, b) =>
        _uploadFreshness(a.uploaded).compareTo(_uploadFreshness(b.uploaded)));
  }
  return out;
}

/// Up to 7 real songs for a category sub-category (e.g. "Salsa" inside "Latin",
/// "French Pop" inside "Pop", or "Drill FR" inside "Rap Français").
///
/// Editorial & Conformance Logic:
/// 1. Uses subcategory-specific seed anchors when available (e.g. Marc Anthony for Salsa,
///    Stromae for French Pop, Gazo for Drill FR).
/// 2. Generates composite queries (queryForSubCategory) when term-driven.
/// 3. Applies strict artist diversity (max 1 track per artist per subcategory row).
/// 4. Respects ambient/spoken-word exceptions (sleep, rain, white noise, focus).
/// 5. Top-ups come strictly from the parent category before any global fallbacks.
/// 6. Structural subs get dedicated strategies (_tuningForSub): New/Trending
///    favour fresh uploads, Popular/Top Songs/Music Videos rank by views,
///    Singles keep only single-shaped releases, Albums keep real album cuts.
/// Categories whose content is spoken-word (shows, episodes) rather than
/// music — they get their own iTunes podcast-episode source in addition to
/// the regular music pipeline.
bool _isSpokenWordCategory(String category, String sub) {
  const spoken = {'podcasts', 'comedy', 'news & politics', 'live events'};
  if (spoken.contains(category.toLowerCase())) return true;
  return sub.toLowerCase().contains('podcast');
}

/// iTunes search term for a podcast subcategory: generic "podcasts" sections
/// map to a broad directory search, everything else becomes "<genre> podcast".
String _podcastTermFor(String sub) {
  final s = sub.trim().toLowerCase();
  if (s.isEmpty || s == 'all' || s == 'all podcasts' ||
      s == 'trending podcasts' || s == 'new podcasts' ||
      s == 'popular podcasts') {
    return 'podcast';
  }
  if (s.contains('podcast')) {
    return 'podcast';
  }
  return '$s podcast';
}

final categorySubSongsProvider =
    FutureProvider.family<List<MuzoItem>, ({String category, String sub, Set<String>? excludedArtists})>(
  (ref, args) async {
    final isAll = args.sub.trim().toLowerCase().startsWith('all ');
    final category = args.category.trim();
    final sub = args.sub.trim();
    final excluded = args.excludedArtists ?? <String>{};
    final isAmbient = isAmbientSubCategory(category, sub);
    final isSpokenCat = _isSpokenWordCategory(category, sub);

    // ─── Podcast categories: REAL podcast episodes only ───
    // iTunes' podcast directory serves full-length MP3 episodes (user_track)
    // that the player streams natively. These sections exist to surface SHOWS,
    // not songs, so they are served exclusively from iTunes episodes — the
    // generic 2-day cache below is never allowed to feed them old song lists.
    // A dedicated fresh cache keeps reopen cheap while guaranteeing real
    // episodes (never genre songs).
    final bucket = ContentCacheService.refreshBucket;
    if (isSpokenCat) {
      final podCacheKey = 'podcat|$category|$sub';
      try {
        final pc = await ContentCacheService.instance.readIfFresh(podCacheKey);
        if (pc != null && pc.length >= 2) {
          return ContentCacheService.rotate(pc, bucket);
        }
      } catch (_) {}
      try {
        final itunesPod = ref.read(itunesApiServiceProvider);
        // Rich search: several directory terms x FR+US storefronts so the
        // rows are long and varied. Generic sections ("All Podcasts", "New",
        // "Trending", "Popular") hit multiple broad terms; genre subs append
        // "podcast" to their own name for a targeted directory search.
        final s = sub.trim().toLowerCase();
        final base = _podcastTermFor(sub);
        final terms = <String>{base};
        if (base == 'podcast') terms.addAll(['new podcast', 'podcasts']);
        final batches = <Future<List<MuzoItem>>>[];
        for (final t in terms.take(3)) {
          batches.add(itunesPod.searchPodcastEpisodesFrUs(t,
              limit: 12, maxPerShow: 2));
        }
        final episodeBatches = await Future.wait(batches)
            .timeout(const Duration(seconds: 18));
        var episodes = dedupeMuzoSongs([
          for (final batch in episodeBatches) ...batch,
        ]);
        // "New Podcasts" and friends: freshest episodes first so the section
        // actually looks like newly-released content (falls back to iTunes'
        // directory order for generic rows).
        if (episodes.length > 1) {
          final isFreshFirst = s == 'new podcasts' ||
              s == 'new' ||
              s == 'latest episodes';
          if (isFreshFirst) {
            episodes.sort((a, b) => (b.releaseDate?.millisecondsSinceEpoch ?? 0)
                .compareTo(a.releaseDate?.millisecondsSinceEpoch ?? 0));
          }
        }
        final podcastList = episodes.take(24).toList();
        if (episodes.length >= 3) {
          unawaited(
              ContentCacheService.instance.write(podCacheKey, podcastList));
          return ContentCacheService.rotate(podcastList, bucket);
        }
      } catch (_) {}
    }

    // ─── 2-day refresh cache ───
    // A fresh (<48h) cached list is served instantly: pages open without any
    // network wait, and every bucket rotation (2 days) both re-fetches from
    // the network and rotates the order, so content visibly renews.
    final cacheKey = 'catsub|$category|$sub';
    try {
      final cached = await ContentCacheService.instance.readIfFresh(cacheKey);
      if (cached != null && cached.length >= 2) {
        return ContentCacheService.rotate(cached, bucket);
      }
    } catch (_) {}

    // Strict category constraint (genre + country + language + region). A
    // geo-scoped section (e.g. "Gospel > Benin Gospel") must ONLY show content
    // that satisfies ALL its constraints — never generic parent-category music.
    final constraint = categoryConstraintFor(category, sub);
    final geoScoped = constraint.isGeoScoped;

    final seenArtists = <String, int>{};
    final seenIds = <String>{};
    final result = <MuzoItem>[];

    void addUnique(
      List<MuzoItem> batch, {
      int maxPerArtist = 1,
      bool applyConstraint = true,
    }) {
      for (final song in _tuneBatchForSub(sub, batch)) {
        if (!isActuallyPlayable(song)) continue;
        if (isJunkSong(song.title, isAmbient: isAmbient)) continue;
        if (applyConstraint && !acceptsForCategory(song, constraint)) continue;
        final idKey = (song.videoId ?? '${song.title}|${song.displayArtist}').toLowerCase();
        if (idKey.isEmpty || seenIds.contains(idKey)) continue;

        final artistKey = primaryArtistName(song.displayArtist).trim().toLowerCase();
        if (artistKey.isNotEmpty && (seenArtists[artistKey] ?? 0) >= maxPerArtist) continue;
        if (maxPerArtist <= 1 &&
            artistKey.isNotEmpty &&
            excluded.contains(artistKey)) continue;

        seenIds.add(idKey);
        if (artistKey.isNotEmpty) {
          seenArtists[artistKey] = (seenArtists[artistKey] ?? 0) + 1;
        }
        result.add(song);
        if (result.length >= 15) break;
      }
    }

    // ─── Charts / Trending: real current tops from Apple's RSS charts ───
    // Each chart sub mirrors a real storefront (France → fr, Nigeria → ng...).
    // Trend entries carry no stream URL, so each pick is resolved to a
    // playable item with one YT search.
    final catLower = category.toLowerCase();
    final isChartCat = catLower == 'charts' ||
        catLower == 'trending' ||
        catLower == 'hit benin';
    // Curated sub-category seeds (non-chart, non-geo) run BEFORE algorithmic
    // resolution so curated artists always lead the section and resolution's
    // early-return (>=3 songs) can't override them (e.g. Rap charts leaking
    // into "Romance > French Love"). Specific seeds also cover structural
    // subs ("All Music" / "Top Songs"); parent seeds are the fallback.
    final subSeeds = seedsForSubCategory(category, sub);
    final useCuratedFirst = subSeeds.isNotEmpty && !isChartCat && !geoScoped;
    if (isChartCat && !isAmbient) {
      try {
        final countries = catLower == 'hit benin'
            ? const ['bj']
            : TrendingService.countriesForSub(sub);
        final pools =
            await Future.wait(countries.map(TrendingService.topSongs));
        final seenTrends = <String>{};
        final trends = <TrendSong>[];
        for (final pool in pools) {
          for (final t in pool) {
            final k = '${t.title}|${t.artist}'.toLowerCase();
            if (seenTrends.contains(k)) continue;
            seenTrends.add(k);
            trends.add(t);
          }
        }
        final api = ref.read(muzoApiServiceProvider);
        for (final t in trends.take(16)) {
          if (result.length >= 15) break;
          try {
            final resp = await api
                .search('${t.title} ${t.artist}', filter: 'songs')
                .timeout(const Duration(seconds: 8));
            addUnique(
              resp.results.take(2).toList(),
              applyConstraint: false,
              maxPerArtist: 3,
            );
          } catch (_) {}
        }
        debugPrint(
            '[Charts] "$category > $sub" trends=${trends.length} result=${result.length}');
        if (result.length >= 3) {
          final chartList = result.take(15).toList();
          unawaited(ContentCacheService.instance.write(cacheKey, chartList));
          return ContentCacheService.rotate(chartList, bucket);
        }
        // Below the minimum → fall through to the regular pipeline rather
        // than showing nothing.
      } catch (_) {}
    }

    // ─── New resolver: dispatch by category type (genre, geo, decades, etc.) ───
    final service = CategoryResolutionService(ref);

    if (useCuratedFirst) {
      // Curated seeds open the section: rotate per 2-day bucket so each
      // refresh leads with different artists → genuinely different songs.
      final off = subSeeds.length > 1 ? bucket % subSeeds.length : 0;
      final orderedSeeds = ContentCacheService.rotate(subSeeds, off);
      final futures = <Future<List<MuzoItem>>>[
        for (final seed in orderedSeeds.take(6))
          ref.watch(categorySongsProvider(seed).future),
      ];
      final batches = await Future.wait(futures);
      for (final batch in batches) {
        addUnique(batch);
        if (result.length >= 8) break;
      }
      // Resolution only tops up when the curated seeds underfill; no
      // early-return so it can never displace the curated artists.
      if (result.length < 8) {
        final resolutionResult = await service
            .resolve(
              category: category,
              sub: sub,
              excludedArtists: excluded,
            )
            .timeout(const Duration(seconds: 18), onTimeout: () =>
                CategoryResolutionResult(
                  songs: [], logs: const [], type: CategoryType.fallback,
                ));
        if (resolutionResult.type != CategoryType.fallback) {
          addUnique(resolutionResult.songs);
          logResolution(resolutionResult);
        }
      }
    } else {
      final resolutionResult = await service
          .resolve(
            category: category,
            sub: sub,
            excludedArtists: excluded,
          )
          .timeout(const Duration(seconds: 18), onTimeout: () =>
              CategoryResolutionResult(
                songs: [], logs: const [], type: CategoryType.fallback,
              ));

      if (resolutionResult.type != CategoryType.fallback) {
        addUnique(resolutionResult.songs);
        logResolution(resolutionResult);
        if (resolutionResult.songs.length >= 3) {
          final resolved = resolutionResult.songs.take(15).toList();
          unawaited(ContentCacheService.instance.write(cacheKey, resolved));
          return ContentCacheService.rotate(resolved, bucket);
        }
      }

      // ─── Fallback: old pipeline for unresolved categories ───
      // Dedicated sub-category seeds are the fallback for geo-scoped and
      // chart sections that keep algorithmic resolution / charts as the
      // primary authority.
      if (subSeeds.isNotEmpty) {
        // Rotate the seed order per 2-day bucket so each refresh leads with
        // different artists → genuinely different songs, not the same top hits.
        final off = subSeeds.length > 1 ? bucket % subSeeds.length : 0;
        final orderedSeeds = ContentCacheService.rotate(subSeeds, off);
        final futures = <Future<List<MuzoItem>>>[
          for (final seed in orderedSeeds.take(6))
            ref.watch(categorySongsProvider(seed).future),
        ];
        final batches = await Future.wait(futures);
        for (final batch in batches) {
          addUnique(batch);
          if (result.length >= 8) break;
        }
      } else {
        final subQuery = queryForSubCategory(category, sub);
        final futures = <Future<List<MuzoItem>>>[
          ref.watch(categorySongsProvider(subQuery).future),
          if (!isAll && subQuery.toLowerCase() != category.toLowerCase())
            ref.watch(categorySongsProvider(category).future),
        ];
        final batches = await Future.wait(futures);
        for (final batch in batches) {
          addUnique(batch);
          if (result.length >= 8) break;
        }
      }
    }

    // ─── Spoken-word categories: iTunes podcast-episode source ───
    // Podcasts / Comedy / News / Live Events have no reliable coverage in the
    // music APIs, but iTunes' podcast directory serves real full-length
    // episodes (MP3) that the player streams natively via user_track.
    if (isSpokenCat && result.length < 7) {
      try {
        final itunes = ref.read(itunesApiServiceProvider);
        final combined = sub.toLowerCase() == category.toLowerCase()
            ? category
            : '$category $sub';
        final episodeBatches = await Future.wait([
          itunes.searchPodcastEpisodesFrUs(sub, limit: 10),
          if (combined.toLowerCase() != sub.toLowerCase())
            itunes.searchPodcastEpisodesFrUs(combined, limit: 10),
        ]);
        for (final batch in episodeBatches) {
          addUnique(batch, maxPerArtist: 3, applyConstraint: false);
          if (result.length >= 8) break;
        }
      } catch (_) {}
    }

    // Strict Category-Scoped top-up.
    if (result.length < 7) {
      final scopedPlan = genrePlanFor(category, sub);
      final scopedTerm = scopedPlan.isEmpty
          ? null
          : (subSeeds.isNotEmpty
              ? scopedPlan.ytifyTerm
              : queryForSubCategory(category, sub));
      final geoTerm = buildScopedSearchTerm(category, sub, scopedTerm ?? '');

      if (geoScoped) {
        if (geoTerm.isNotEmpty) {
          try {
            final scopedBatch = await ref
                .read(muzoApiServiceProvider)
                .search(geoTerm, filter: 'songs')
                .timeout(const Duration(seconds: 12));
            addUnique(_prioritizeWestern(scopedBatch.results));
          } catch (_) {}
        }
        if (result.length < 7) {
          try {
            final scopedBatch = await ref
                .read(muzoApiServiceProvider)
                .search(geoTerm, filter: 'songs')
                .timeout(const Duration(seconds: 12));
            addUnique(_prioritizeWestern(scopedBatch.results));
          } catch (_) {}
        }
        if (result.length < 7 && geoTerm.split(' ').length > 1) {
          final flipped = geoTerm.split(' ').reversed.join(' ');
          try {
            final scopedBatch = await ref
                .read(muzoApiServiceProvider)
                .search(flipped, filter: 'songs')
                .timeout(const Duration(seconds: 12));
            addUnique(_prioritizeWestern(scopedBatch.results));
          } catch (_) {}
        }
      } else {
        final categoryFuture = ref.watch(categorySongsProvider(category).future);
        if (geoTerm.isNotEmpty) {
          try {
            final scopedBatch = await ref
                .read(muzoApiServiceProvider)
                .search(geoTerm, filter: 'songs')
                .timeout(const Duration(seconds: 12));
            addUnique(_prioritizeWestern(scopedBatch.results));
          } catch (_) {}
        }
        if (result.length < 7) {
          final categoryBatch = await categoryFuture;
          addUnique(categoryBatch);
        }
      }
    }

    // Last resort: genre batch from Jamendo/Audius/iTunes.
    if (result.isEmpty) {
      final plan = genrePlanFor(category, sub);
      if (!plan.isEmpty) {
        final genreBatch = await fetchGenreBatch(
          ref,
          plan,
          perSource: 8,
        ).timeout(const Duration(seconds: 14), onTimeout: () => const []);
        addUnique(genreBatch);
      }
      if (result.isEmpty) {
        try {
          final subTerm = isAll ? category : queryForSubCategory(category, sub);
          final resp = await ref
              .read(muzoApiServiceProvider)
              .search(subTerm, filter: 'songs')
              .timeout(const Duration(seconds: 10));
          addUnique(_prioritizeWestern(resp.results));
        } catch (_) {}
      }
    }

    // ─── Modern boost: current chart-matching tracks in every music sub ───
    // A couple of TODAY's chart tracks (genre-matched via iTunes metadata)
    // are inserted near the front so even healthy sections feel current, and
    // every refresh cycle brings different ones.
    if (!isChartCat &&
        !useCuratedFirst &&
        !geoScoped &&
        !_isSpokenWordCategory(category, sub) &&
        result.length < 9) {
      try {
        final picks =
            await TrendingService.picksForCategory(catLower, bucket, 3);
        final startLen = result.length;
        if (picks.isNotEmpty) {
          final api = ref.read(muzoApiServiceProvider);
          for (final t in picks) {
            if (result.length >= 15) break;
            try {
              final resp = await api
                  .search('${t.title} ${t.artist}', filter: 'songs')
                  .timeout(const Duration(seconds: 8));
              addUnique(
                resp.results.take(1).toList(),
                applyConstraint: false,
                maxPerArtist: 1,
              );
            } catch (_) {}
          }
          // Surface the freshly added modern tracks within the visible first
          // cards instead of leaving them as an invisible tail.
          final modernCount = result.length - startLen;
          if (modernCount > 0) {
            final modern = result.sublist(startLen);
            result.removeRange(startLen, result.length);
            result.insertAll(result.length >= 2 ? 2 : 0, modern);
          }
        }
      } catch (_) {}
    }

    debugPrint(
        '[CatSub] "$category > $sub" seeds=${subSeeds.length} result=${result.length}');
    final finalList = result.take(10).toList();
    // Cache only sections that meet the display minimum, so a transient
    // network failure is never frozen for 2 days.
    if (finalList.length >= 3) {
      unawaited(ContentCacheService.instance.write(cacheKey, finalList));
    }
    return ContentCacheService.rotate(finalList, bucket);
  },
);

/// 100+ real songs for an artist page.
///
/// Primary source: the artist's own "Top songs" playlist, resolved via
/// search(artist, filter: 'artists') -> getArtistDetails(browseId) ->
/// getPlaylistDetails(playlistId). That endpoint alone returns ~100 tracks.
/// If that path fails (or yields fewer than [minCount] songs) the provider
/// falls back to paging the plain search endpoint with continuation tokens,
/// which tops out around 40 songs. It never returns an empty list: a final
/// plain search for the artist name guarantees at least some tracks.
final artistSongsProvider =
    FutureProvider.family<List<MuzoItem>, String>((ref, artist) async {
  if (artist.trim().isEmpty) return <MuzoItem>[];
  try {
  final apiService = ref.read(muzoApiServiceProvider);

  final seen = <String>{};
  final songs = <MuzoItem>[];
  void addUnique(List<MuzoItem> batch) {
    for (final song in batch) {
      final key = (song.videoId ?? '${song.title}|${song.displayArtist}')
          .toLowerCase();
      if (key.isEmpty || seen.contains(key)) continue;
      if (song.videoId == null && song.title.isEmpty) continue;
      seen.add(key);
      songs.add(song);
    }
  }

  final searchQuery = primaryArtistName(artist);

  // Primary: artist browse playlist (~100 tracks).
  try {
    final artistSearch =
        await apiService.search(searchQuery, filter: 'artists');
    final results = _prioritizeWestern(artistSearch.results);
    if (results.isNotEmpty) {
      final match = results.firstWhere(
        (r) =>
            (r.browseId != null && r.browseId!.isNotEmpty) &&
            r.title.trim().toLowerCase() == searchQuery.trim().toLowerCase(),
        orElse: () => results.firstWhere(
          (r) => r.browseId != null && r.browseId!.isNotEmpty,
          orElse: () => results.first,
        ),
      );
      final browseId = match.browseId;
      if (browseId != null && browseId.isNotEmpty) {
        final details = await apiService.getArtistDetails(browseId);
        final playlistId = details?.playlistId ?? '';
        if (playlistId.isNotEmpty) {
          final playlist = await apiService.getPlaylistDetails(playlistId);
          if (playlist != null && playlist.tracks.isNotEmpty) {
            addUnique(playlist.tracks);
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Artist playlist path failed for "$artist": $e');
  }

  // Supplement / fallback: paged plain search. Only keep songs that are
  // actually by the artist (search is fuzzy and would otherwise mix in
  // unrelated tracks). Matches any individual artist token, not the whole
  // comma-joined string.
  final tokens = _artistTokens(searchQuery);
  String? token;
  try {
    for (var page = 0; page < 8 && songs.length < 120; page++) {
      final response = await apiService.search(searchQuery, filter: 'songs',
          continuationToken: token);
      final batch = _prioritizeWestern(response.results)
          .where((s) {
            final names = (s.artists ?? const <MuzoArtist>[])
                .map((a) => a.name)
                .join(' ')
                .toLowerCase();
            final haystack = '${s.displayArtist} $names'.toLowerCase();
            return tokens.any(haystack.contains);
          })
          .toList();
      addUnique(batch);
      token = response.continuationToken;
      if (token == null || token.isEmpty) break;
      if (response.results.isEmpty) break;
    }
  } catch (e) {
    debugPrint('Artist paged search failed for "$artist": $e');
  }

  // Last resort: never return an empty page. A plain (unfiltered) search for
  // the artist name gives the page real content even when the artist is not
  // indexed as a browsable artist.
  if (songs.isEmpty) {
    try {
      final response = await apiService.search(searchQuery, filter: 'songs');
      addUnique(_prioritizeWestern(response.results));
    } catch (e) {
      debugPrint('Artist fallback search failed for "$artist": $e');
    }
  }

  // ─── External API fallbacks (parallel, fast) ───
  // Run iTunes in parallel to discover extra songs the YouTube
  // backend missed. Then resolve each title to a FULL YouTube track via ytify
  // (no 30s preview clips). Resolution is batched in parallel for speed.
  if (songs.length < 20) {
    final discovered = <String>[];
    // Discover titles from the iTunes catalog (fast, parallel). Resolved to
    // FULL YouTube tracks below (never 30s previews).
    try {
      final itunes = await ItunesApiService().searchSongsFrUs(searchQuery, limit: 15);
      for (final it in itunes) {
        final key = it.title.toLowerCase();
        if (!seen.contains(key) && it.title.isNotEmpty) {
          discovered.add('${it.title} ${primaryArtistName(it.displayArtist)}');
          seen.add(key);
        }
      }
    } catch (e) {
      debugPrint('Artist iTunes discovery failed for "$artist": $e');
    }
    // Resolve discovered titles → full YouTube tracks in parallel batches.
    if (discovered.isNotEmpty) {
      final batchFutures = <Future<List<MuzoItem>>>[];
      for (final q in discovered.take(15)) {
        batchFutures.add(
          apiService.search(q, filter: 'songs').then((r) => r.results).catchError((_) => <MuzoItem>[]),
        );
      }
      try {
        final batchResults = await Future.wait(batchFutures);
        for (final batch in batchResults) {
          addUnique(batch.take(1).toList());
          if (songs.length >= 30) break;
        }
      } catch (e) {
        debugPrint('Artist ytify resolve failed for "$artist": $e');
      }
    }
  }

  return songs;
  } catch (e) {
    debugPrint('artistSongsProvider crashed for "$artist": $e');
    return <MuzoItem>[];
  }
});

/// Related artists for the artist page's "Fans also like" row: the backend
/// artist search for the same query, minus the artist himself.
final relatedArtistsProvider =
    FutureProvider.family<List<MuzoItem>, String>((ref, artist) async {
  final q = primaryArtistName(artist);
  if (q.trim().isEmpty) return [];
  final apiService = ref.read(muzoApiServiceProvider);
  try {
    final response = await apiService.search(q, filter: 'artists');
    final self = q.trim().toLowerCase();
    return response.results
        .where((r) => r.title.trim().toLowerCase() != self)
        .toList();
  } catch (e) {
    debugPrint('Related artists failed for "$artist": $e');
    return [];
  }
});

/// Key for [collectionTracksProvider]: identifies one album or playlist from
/// the search grid precisely enough to fetch its EXACT track list.
typedef CollectionKey = ({
  String title,
  String artist,
  String browseId,
  bool isAlbum,
});

/// Exact track list of a searched album or playlist. Primary path uses the
/// browse id straight into the backend album/playlist endpoints so the page
/// shows the real tracklist. Falls back to an exact-name song search when the
/// browse id is missing or the endpoints fail — never an empty page.
final collectionTracksProvider =
    FutureProvider.family<List<MuzoItem>, CollectionKey>((ref, key) async {
  final apiService = ref.read(muzoApiServiceProvider);
  final id = key.browseId.trim();
  if (id.isNotEmpty) {
    try {
      if (key.isAlbum) {
        final album = await apiService.getAlbumDetails(id);
        if (album != null && album.tracks.isNotEmpty) return album.tracks;
      } else {
        final playlist = await apiService.getPlaylistDetails(id);
        if (playlist != null && playlist.tracks.isNotEmpty) {
          return playlist.tracks;
        }
      }
    } catch (e) {
      debugPrint(
          'Collection "${key.title}" browse fetch failed (${key.isAlbum ? 'album' : 'playlist'}): $e');
    }
  }
  // Fallback: exact-name search keeps the page on-topic.
  try {
    final q = '${key.title} ${key.artist}'.trim();
    final response = await apiService.search(q, filter: 'songs');
    return response.results.take(40).toList();
  } catch (e) {
    debugPrint('Collection fallback search failed for "${key.title}": $e');
    return [];
  }
});

/// Best-guess primary artist from a display string like "Ninho, Niska" or
/// "Sécu - Franglish, Ninho" -> the first real artist name.
String primaryArtistName(String input) {
  var name = input.trim();
  if (name.isEmpty) return name;
  // Cut off separators: commas, " & ", " x ", " feat. ", " ft. ", "-"
  name = name.split(RegExp(r'[,]| & | x | feat\.? | ft\.? ')).first.trim();
  // Remove parenthetical suffixes like "(feat. Niska)"
  name = name.replaceAll(RegExp(r'\s*\(feat.*\)\s*'), '').trim();
  return name;
}

/// Individual artist tokens from a name, used for fuzzy matching.
List<String> _artistTokens(String name) {
  final tokens = <String>{};
  final lower = name.trim().toLowerCase();
  if (lower.isNotEmpty) tokens.add(lower);
  final split = lower
      .split(RegExp(r'[,]| & | x | feat\.? | ft\.? '))
      .map((t) => t.trim())
      .where((t) => t.length >= 2);
  tokens.addAll(split);
  return tokens.toList();
}


/// Heuristic: true when a search result is very likely Indian content
/// (Hindi/Tamil/Telugu/etc. film music) so it can be demoted below
/// French / US / Afro / Euro results in "All" searches.
bool _looksIndian(MuzoItem item) {
  final text = [
    item.title,
    item.displayArtist,
    item.channelName ?? '',
  ].join(' ').toLowerCase();

  // Devanagari, Bengali, Gurmukhi, Gujarati, Telugu, Kannada, Malayalam,
  // Tamil and Odia scripts.
  if (RegExp(
    r'[\u0900-\u097F\u0980-\u09FF\u0A00-\u0A7F\u0A80-\u0AFF'
    r'\u0B00-\u0B7F\u0B80-\u0BFF\u0C00-\u0C7F\u0C80-\u0CFF'
    r'\u0D00-\u0D7F]',
  ).hasMatch(text)) {
    return true;
  }

  const markers = [
    'bollywood',
    'hindi song',
    'punjabi',
    'tamil song',
    'telugu song',
    'malayalam song',
    'kannada song',
    'bhojpuri',
    't-series',
    'saregama',
    'zee music',
    'sony music india',
    'tips official',
    'speed records',
    'arijit singh',
    'neha kakkar',
    'dhvani bhanushali',
    'jubin nautiyal',
    'atif aslam',
    'sidhu moosewala',
    'yo yo honey singh',
    'diljit dosanjh',
    'karan aujla',
    'shreya ghoshal',
    'lata mangeshkar',
    'kishore kumar',
    'himesh reshammiya',
    'amitabh bachchan',
    'kabhi khushi',
    'devdas',
    'jab harry met sejal',
    'raanjhanaa',
    'dangal',
    'bajrangi',
    'dilwale',
    'ae dil hai mushkil',
    'tamasha',
    '(from "',
  ];
  return markers.any(text.contains);
}

/// Stable partition: non-Indian (French / US / Afro / Euro...) results first,
/// Indian results moved to the end, preserving original order within each
/// group so YouTube's own relevance ranking is untouched.
List<MuzoItem> _prioritizeWestern(List<MuzoItem> results) {
  final preferred = <MuzoItem>[];
  final indian = <MuzoItem>[];
  for (final item in results) {
    (_looksIndian(item) ? indian : preferred).add(item);
  }
  return [...preferred, ...indian];
}

/// Remove duplicate songs (same videoId, or title+artist when videoId is
/// null) so an artist's tracks never appear twice in one result list.
List<MuzoItem> _dedupeSongs(List<MuzoItem> songs) => dedupeMuzoSongs(songs);

/// Real cover image for a Search "Browse All" category. Chains free artwork
/// providers (all keyless) until one returns an image:
/// iTunes -> MusicBrainz + Cover Art Archive -> Wikipedia -> Wikimedia Commons
/// -> Internet Archive -> Openverse -> Google Books -> muzo thumbnail.
/// Returns null only when every source fails -> the UI shows the bundled cover.
final categoryImageProvider =
    FutureProvider.family<String?, String>((ref, query) async {
  if (query.isEmpty) return null;
  final apiService = ref.read(muzoApiServiceProvider);

  final providers = <Future<String?> Function()>[
    () => _iTunesCover(query),
    () => _musicBrainzCover(query),
    () => _wikipediaCover(query),
    () => _commonsCover(query),
    () => _archiveCover(query),
    () => _openverseCover(query),
    () => _booksCover(query),
  ];
  for (final provider in providers) {
    try {
      final url = await provider();
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {}
  }

  // Last resort: muzo search thumbnail (may be a video/album thumb).
  try {
    final response =
        await apiService.search(query, filter: 'songs').timeout(
              const Duration(seconds: 10),
            );
    for (final item in response.results) {
      if (item.thumbnails.isNotEmpty && item.thumbnails.last.url.isNotEmpty) {
        return item.thumbnails.last.url;
      }
    }
  } catch (_) {}

  return null;
});

Future<String?> _iTunesCover(String query) async {
  final uri = Uri.parse('https://itunes.apple.com/search').replace(
    queryParameters: {'term': query, 'entity': 'album', 'limit': '1'},
  );
  final resp = await http.get(uri).timeout(const Duration(seconds: 8));
  if (resp.statusCode != 200) return null;
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final results = data['results'] as List?;
  if (results == null || results.isEmpty) return null;
  final art = (results.first as Map)['artworkUrl100'] as String?;
  if (art == null || art.isEmpty) return null;
  return art.replaceFirst('100x100bb', '300x300bb');
}

Future<String?> _musicBrainzCover(String query) async {
  final mbUri = Uri.parse('https://musicbrainz.org/ws/2/release/').replace(
    queryParameters: {'query': 'release:$query', 'fmt': 'json', 'limit': '1'},
  );
  final mbResp = await http.get(
    mbUri,
    headers: const {'User-Agent': 'Tunefy/3.9.0 (music app)'},
  ).timeout(const Duration(seconds: 8));
  if (mbResp.statusCode != 200) return null;
  final mbData = jsonDecode(mbResp.body) as Map<String, dynamic>;
  final releases = mbData['releases'] as List?;
  if (releases == null || releases.isEmpty) return null;
  final releaseId = (releases.first as Map)['id'] as String?;
  if (releaseId == null || releaseId.isEmpty) return null;
  final caResp = await http.head(
    Uri.parse('https://coverartarchive.org/release/$releaseId/front-500'),
  ).timeout(const Duration(seconds: 8));
  if (caResp.statusCode != 200) return null;
  return 'https://coverartarchive.org/release/$releaseId/front-500';
}

Future<String?> _wikipediaCover(String query) async {
  final uri = Uri.parse('https://en.wikipedia.org/w/api.php').replace(
    queryParameters: {
      'action': 'query',
      'generator': 'search',
      'gsrsearch': query,
      'gsrnamespace': '0',
      'gsrlimit': '3',
      'prop': 'pageimages',
      'piprop': 'thumbnail',
      'pithumbsize': '300',
      'format': 'json',
    },
  );
  final resp = await http.get(
    uri,
    headers: const {'User-Agent': 'Tunefy/3.9.0 (music app)'},
  ).timeout(const Duration(seconds: 8));
  if (resp.statusCode != 200) return null;
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final pages = data['query']?['pages'];
  if (pages is! Map) return null;
  for (final page in pages.values) {
    final thumb = (page as Map)['thumbnail']?['source'] as String?;
    if (thumb != null && thumb.isNotEmpty) return thumb;
  }
  return null;
}

Future<String?> _commonsCover(String query) async {
  final uri = Uri.parse('https://commons.wikimedia.org/w/api.php').replace(
    queryParameters: {
      'action': 'query',
      'generator': 'search',
      'gsrsearch': '$query music cover',
      'gsrnamespace': '6',
      'gsrlimit': '3',
      'prop': 'imageinfo',
      'iiprop': 'url',
      'iiurlwidth': '300',
      'format': 'json',
    },
  );
  final resp = await http.get(
    uri,
    headers: const {'User-Agent': 'Tunefy/3.9.0 (music app)'},
  ).timeout(const Duration(seconds: 8));
  if (resp.statusCode != 200) return null;
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final pages = data['query']?['pages'];
  if (pages is! Map) return null;
  for (final page in pages.values) {
    final imageinfo = (page as Map)['imageinfo'];
    if (imageinfo is List && imageinfo.isNotEmpty) {
      final thumb = (imageinfo.first as Map)['thumburl'] as String?;
      if (thumb != null && thumb.isNotEmpty) return thumb;
    }
  }
  return null;
}

Future<String?> _archiveCover(String query) async {
  final uri = Uri.parse('https://archive.org/advancedsearch.php').replace(
    queryParameters: {
      'q': '$query AND mediatype:audio',
      'fl[]': 'identifier',
      'rows': '1',
      'output': 'json',
    },
  );
  final resp = await http.get(uri).timeout(const Duration(seconds: 8));
  if (resp.statusCode != 200) return null;
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final docs = data['response']?['docs'] as List?;
  if (docs == null || docs.isEmpty) return null;
  final id = (docs.first as Map)['identifier'] as String?;
  if (id == null || id.isEmpty) return null;
  return 'https://archive.org/services/img/$id';
}

Future<String?> _openverseCover(String query) async {
  final uri = Uri.parse('https://api.openverse.org/v1/images/').replace(
    queryParameters: {'q': query, 'per_page': '1'},
  );
  final resp = await http.get(
    uri,
    headers: const {'User-Agent': 'Tunefy/3.9.0 (music app)'},
  ).timeout(const Duration(seconds: 8));
  if (resp.statusCode != 200) return null;
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final results = data['results'] as List?;
  if (results == null || results.isEmpty) return null;
  final url = (results.first as Map)['url'] as String?;
  if (url == null || url.isEmpty) return null;
  return url;
}

Future<String?> _booksCover(String query) async {
  final uri = Uri.parse('https://www.googleapis.com/books/v1/volumes').replace(
    queryParameters: {'q': '$query music', 'maxResults': '1'},
  );
  final resp = await http.get(uri).timeout(const Duration(seconds: 8));
  if (resp.statusCode != 200) return null;
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  final items = data['items'] as List?;
  if (items == null || items.isEmpty) return null;
  final links = (items.first as Map)['volumeInfo']?['imageLinks'] as Map?;
  final thumb = links?['thumbnail'] as String?;
  if (thumb == null || thumb.isEmpty) return null;
  return thumb.replaceFirst('zoom=1', 'zoom=0');
}

