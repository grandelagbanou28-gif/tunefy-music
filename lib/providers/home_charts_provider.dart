import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/content_cache_service.dart';
import 'package:muzo/services/muzo_api_service.dart';
import 'package:muzo/services/trending_service.dart';

/// Editorial data for the "Découvrir tout" home block, 100% YouTube-playable.
///
/// Backed by Apple's public RSS storefronts (real per-country top songs,
/// albums and playlists) whose entries are resolved to playable YouTube
/// items through muzoapi — exactly like the Charts category pipeline. No
/// third-party streaming service (Deezer, etc.) is involved any more.
class HomeCharts {
  final List<MuzoItem> tracks;
  final List<MuzoItem> albums;
  final List<MuzoItem> playlists;

  const HomeCharts({
    this.tracks = const [],
    this.albums = const [],
    this.playlists = const [],
  });
}

final homeChartsProvider = FutureProvider<HomeCharts>((ref) async {
  final api = ref.read(muzoApiServiceProvider);
  final bucket = ContentCacheService.refreshBucket;

  Future<List<MuzoItem>?> fromCache(String key) async {
    try {
      final raw =
          await ContentCacheService.instance.readJsonIfFresh(key);
      if (raw != null && raw.isNotEmpty) {
        return raw
            .whereType<Map>()
            .map((m) => MuzoItem.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  Future<List<MuzoItem>> resolveInBatches(
    List<String> queries,
    String filter, {
    bool song = false,
  }) async {
    final out = <MuzoItem>[];
    final seenIds = <String>{};
    for (var i = 0; i < queries.length; i += 5) {
      final chunk = queries.skip(i).take(5).toList();
      final results = await Future.wait(chunk.map((q) async {
        try {
          final resp = await api
              .search(q, filter: filter)
              .timeout(const Duration(seconds: 9));
          for (final r in resp.results) {
            if (song) {
              if (r.videoId != null) return r;
            } else if ((r.browseId ?? r.videoId) != null) {
              return r;
            }
          }
        } catch (_) {}
        return null;
      }));
      for (final r in results.whereType<MuzoItem>()) {
        final idKey = (r.videoId ?? r.browseId ?? '${r.title}|${r.displayArtist}')
            .toLowerCase();
        if (idKey.isEmpty || seenIds.contains(idKey)) continue;
        seenIds.add(idKey);
        out.add(r);
      }
      if (out.length >= 20) break;
    }
    return out;
  }

  // ─── Tracks (top songs FR + US → YouTube) ───
  var tracks = await fromCache('homecharts|tracks');
  if (tracks == null) {
    final pool = await Future.wait(
        [TrendingService.topSongs('fr'), TrendingService.topSongs('us')]);
    final seen = <String>{};
    final queries = <String>[];
    for (final list in pool) {
      for (final t in list) {
        final k = '${t.title}|${t.artist}'.toLowerCase();
        if (seen.contains(k)) continue;
        seen.add(k);
        queries.add('${t.title} ${t.artist}');
        if (queries.length >= 24) break;
      }
    }
    tracks = await resolveInBatches(queries, 'songs', song: true);
    if (tracks.isNotEmpty) {
      await ContentCacheService.instance
          .writeJson('homecharts|tracks', tracks.map((i) => i.toJson()).toList());
    }
  }

  // ─── Albums (RSS top albums → YouTube albums) ───
  var albums = await fromCache('homecharts|albums');
  if (albums == null) {
    final pool = await Future.wait(
        [TrendingService.topAlbums('fr'), TrendingService.topAlbums('us')]);
    final seen = <String>{};
    final queries = <String>[];
    for (final list in pool) {
      for (final a in list) {
        final k = '${a.title}|${a.artist}'.toLowerCase();
        if (seen.contains(k)) continue;
        seen.add(k);
        queries.add('${a.title} ${a.artist}');
        if (queries.length >= 12) break;
      }
    }
    albums = await resolveInBatches(queries, 'albums');
    if (albums.isNotEmpty) {
      await ContentCacheService.instance
          .writeJson('homecharts|albums', albums.map((i) => i.toJson()).toList());
    }
  }

  // ─── Playlists (RSS top playlists → YouTube playlists) ───
  var playlists = await fromCache('homecharts|playlists');
  if (playlists == null) {
    final pool = await Future.wait([
      TrendingService.topPlaylists('fr'),
      TrendingService.topPlaylists('us'),
    ]);
    final seen = <String>{};
    final queries = <String>[];
    for (final list in pool) {
      for (final p in list) {
        final k = p.title.toLowerCase();
        if (seen.contains(k)) continue;
        seen.add(k);
        queries.add(p.title);
        if (queries.length >= 12) break;
      }
    }
    playlists = await resolveInBatches(queries, 'playlists');
    if (playlists.isNotEmpty) {
      await ContentCacheService.instance.writeJson('homecharts|playlists',
          playlists.map((i) => i.toJson()).toList());
    }
  }

  final rotated = ContentCacheService.rotate;
  return HomeCharts(
    tracks: rotated(tracks, bucket),
    albums: rotated(albums, bucket),
    playlists: rotated(playlists, bucket),
  );
});
