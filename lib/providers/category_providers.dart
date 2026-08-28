import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/services/category_curator.dart';

const _timeout = Duration(seconds: 8);

/// The two most recent years (e.g. 2025 & 2026 today, 2026 & 2027 next year),
/// computed at runtime so the app always shows fresh content without code
/// changes in the years to come.
({int current, int previous}) _recentYears() {
  final now = DateTime.now();
  return (current: now.year, previous: now.year - 1);
}

/// True when the given release date falls in one of the two most recent years.
bool _isRecent(DateTime? date) {
  if (date == null) return false;
  final years = _recentYears();
  return date.year == years.current || date.year == years.previous;
}

/// Podcasts keep a release date only if it is one of the two most recent
/// years; podcasts without a date are kept so the section never empties.
bool _isRecentPodcast(DateTime? date) {
  if (date == null) return true;
  final years = _recentYears();
  return date.year == years.current || date.year == years.previous;
}

/// Keyless iTunes Search API helper shared by the category providers.
/// Throws on network/timeout/HTTP failures so callers can show an error state;
/// returns [] only when iTunes genuinely has no results for the term.
Future<List<Map<String, dynamic>>> _itunesSearch(
  String term,
  String entity,
  int limit,
) async {
  final uri = Uri.parse('https://itunes.apple.com/search').replace(
    queryParameters: {'term': term, 'entity': entity, 'limit': '$limit'},
  );
  final resp = await http.get(uri).timeout(_timeout);
  if (resp.statusCode != 200) {
    throw Exception('iTunes search failed (HTTP ${resp.statusCode})');
  }
  final data = jsonDecode(resp.body) as Map<String, dynamic>;
  return ((data['results'] as List?) ?? [])
      .map((e) => e as Map<String, dynamic>)
      .toList();
}

/// True when a [haystack] (title, artist or album) contains every word of
/// [needle], so generic results that only matched one stray word are dropped.
bool _containsEveryWord(String haystack, String needle) {
  final text = haystack.toLowerCase();
  return needle
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty && w.length > 1)
      .every(text.contains);
}

String _hd(String? url) =>
    (url == null || url.isEmpty) ? '' : url.replaceFirst('100x100bb', '600x600bb');

/// A real album found on the iTunes Search API for a category.
class CategoryAlbum {
  const CategoryAlbum({
    required this.name,
    required this.artist,
    required this.coverUrl,
    this.releaseDate,
    this.trackCount = 0,
  });

  final String name;
  final String artist;
  final String coverUrl;
  final DateTime? releaseDate;
  final int trackCount;

  /// EPs are albums with 3-6 tracks.
  bool get isEp => trackCount >= 3 && trackCount <= 6;

  int get year => releaseDate?.year ?? 0;
}

/// A real artist found on the iTunes Search API for a category.
class CategoryArtist {
  const CategoryArtist({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;
}

/// A real single/track found on the iTunes Search API for a category.
class CategoryTrack {
  const CategoryTrack({
    required this.name,
    required this.artist,
    required this.coverUrl,
    required this.duration,
    this.releaseDate,
  });

  final String name;
  final String artist;
  final String coverUrl;
  final Duration duration;
  final DateTime? releaseDate;
}

/// A real podcast found on the iTunes Search API for a category.
class CategoryPodcast {
  const CategoryPodcast({
    required this.name,
    required this.host,
    required this.coverUrl,
  });

  final String name;
  final String host;
  final String coverUrl;
}

/// Real albums for a "Browse All" category (iTunes album entity, keyless).
///
/// Editorial logic: the section is driven by the category's curated seed
/// artists (internationally relevant hitmakers), each fetched for their
/// current releases, then deduplicated by collection id, filtered to the two
/// most recent years and sorted newest first. The raw category-term search is
/// only used to top things up. For uncatalogued queries (e.g. an artist name
/// from an artist page) the term path takes over on its own.
final categoryAlbumsProvider =
    FutureProvider.family<List<CategoryAlbum>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final year = DateTime.now().year;
  final seeds = seedsFor(query);
  final yearTerm = query.contains(year.toString())
      ? query
      : '$query $year';

  final seenIds = <String>{};
  final albums = <CategoryAlbum>[];

  Future<void> collect(String term, int limit, {bool strict = false}) async {
    final results = await _itunesSearch(term, 'album', limit);
    for (final r in results) {
      final name = r['collectionName'] as String?;
      final art = _hd(r['artworkUrl100'] as String?);
      final id = r['collectionId']?.toString() ?? '';
      final artist = (r['artistName'] as String?) ?? '';
      if (name == null || name.isEmpty || art.isEmpty) continue;
      if (strict && !_containsEveryWord(name, query) &&
          !_containsEveryWord(artist, query)) {
        continue;
      }
      if (id.isNotEmpty && seenIds.contains(id)) continue;
      final releaseDate =
          DateTime.tryParse((r['releaseDate'] as String?) ?? '');
      if (!_isRecent(releaseDate)) continue;
      if (id.isNotEmpty) seenIds.add(id);
      albums.add(
        CategoryAlbum(
          name: name,
          artist: artist,
          coverUrl: art,
          releaseDate: releaseDate,
          trackCount: (r['trackCount'] as num?)?.toInt() ?? 0,
        ),
      );
    }
  }

  if (seeds.isNotEmpty) {
    for (final seed in seeds.take(6)) {
      await collect(seed, 4, strict: false);
    }
    await collect(yearTerm, 12, strict: true);
  } else {
    await collect(yearTerm, 30, strict: true);
  }

  albums.sort((a, b) {
    final d = (b.releaseDate?.millisecondsSinceEpoch ?? 0)
        .compareTo(a.releaseDate?.millisecondsSinceEpoch ?? 0);
    if (d != 0) return d;
    return b.trackCount.compareTo(a.trackCount);
  });
  return albums.take(12).toList();
});

/// Real artists for a "Browse All" category (iTunes musicArtist entity).
///
/// The seed artists are the section: they are already the genre anchors an
/// editor would pick. Artwork is resolved from iTunes for each seed. For
/// uncatalogued queries (artist pages, raw terms) a plain artist search runs.
final categoryArtistsProvider =
    FutureProvider.family<List<CategoryArtist>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final seeds = seedsFor(query);
  if (seeds.isNotEmpty) {
    final artists = <CategoryArtist>[];
    final seen = <String>{};
    for (final seed in seeds.take(8)) {
      final key = seed.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      try {
        final results = await _itunesSearch(seed, 'musicArtist', 1);
        final r = results.isNotEmpty ? results.first : null;
        final name = (r?['artistName'] as String?) ?? seed;
        artists.add(
          CategoryArtist(
            name: name,
            imageUrl: _hd(r?['artworkUrl100'] as String?),
          ),
        );
      } catch (_) {
        artists.add(CategoryArtist(name: seed, imageUrl: ''));
      }
    }
    return artists;
  }
  final results = await _itunesSearch(query, 'musicArtist', 12);
  final artists = <CategoryArtist>[];
  for (final r in results) {
    final name = r['artistName'] as String?;
    if (name == null || name.isEmpty) continue;
    artists.add(CategoryArtist(name: name, imageUrl: _hd(r['artworkUrl100'] as String?)));
  }
  return artists;
});

/// Real singles/tracks for a "Browse All" category (iTunes song entity).
///
/// Same editorial pipeline as the albums provider: curated seed artists first,
/// raw term as a strict top-up, deduplicated by track id, filtered to the two
/// most recent years and sorted newest first.
final categoryTracksProvider =
    FutureProvider.family<List<CategoryTrack>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final year = DateTime.now().year;
  final seeds = seedsFor(query);
  final yearTerm = query.contains(year.toString())
      ? query
      : '$query $year';

  final seenIds = <String>{};
  final tracks = <CategoryTrack>[];

  Future<void> collect(String term, int limit, {bool strict = false}) async {
    final results = await _itunesSearch(term, 'song', limit);
    for (final r in results) {
      final name = r['trackName'] as String?;
      final art = _hd(r['artworkUrl100'] as String?);
      final id = r['trackId']?.toString() ?? '';
      final artist = (r['artistName'] as String?) ?? '';
      if (name == null || name.isEmpty || art.isEmpty) continue;
      if (strict && !_containsEveryWord(name, query) &&
          !_containsEveryWord(artist, query)) {
        continue;
      }
      if (id.isNotEmpty && seenIds.contains(id)) continue;
      final releaseDate =
          DateTime.tryParse((r['releaseDate'] as String?) ?? '');
      if (!_isRecent(releaseDate)) continue;
      if (id.isNotEmpty) seenIds.add(id);
      tracks.add(
        CategoryTrack(
          name: name,
          artist: artist,
          coverUrl: art,
          duration: Duration(milliseconds: (r['trackTimeMillis'] as num?)?.toInt() ?? 0),
          releaseDate: releaseDate,
        ),
      );
    }
  }

  if (seeds.isNotEmpty) {
    for (final seed in seeds.take(6)) {
      await collect(seed, 5, strict: false);
    }
    await collect(yearTerm, 15, strict: true);
  } else {
    await collect(yearTerm, 40, strict: true);
  }

  tracks.sort((a, b) => (b.releaseDate?.millisecondsSinceEpoch ?? 0)
      .compareTo(a.releaseDate?.millisecondsSinceEpoch ?? 0));
  return tracks.take(20).toList();
});

/// Real podcasts for a "Browse All" category (iTunes podcast entity).
/// Podcasts whose latest episode is from one of the two most recent years.
final categoryPodcastsProvider =
    FutureProvider.family<List<CategoryPodcast>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final results = await _itunesSearch(query, 'podcast', 20);
  final podcasts = <CategoryPodcast>[];
  final seen = <String>{};
  for (final r in results) {
    final name = r['collectionName'] as String?;
    final releaseDate =
        DateTime.tryParse((r['releaseDate'] as String?) ?? '');
    if (name == null || name.isEmpty) continue;
    if (!_isRecentPodcast(releaseDate)) continue;
    if (seen.contains(name.toLowerCase())) continue;
    seen.add(name.toLowerCase());
    podcasts.add(
      CategoryPodcast(
        name: name,
        host: (r['artistName'] as String?) ?? '',
        coverUrl: _hd(r['artworkUrl100'] as String?),
      ),
    );
  }
  return podcasts.take(10).toList();
});
