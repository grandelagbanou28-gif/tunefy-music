import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/services/muzo_service.dart';
import 'package:tunefy/services/itunes_service.dart';
import 'package:tunefy/services/music_catalog_service.dart';
import 'package:tunefy/services/search_service.dart';

class SyncContent {
  final String title;
  final String artist;
  final String? album;
  final String? imageUrl;
  final String? duration;
  final String source;
  final String id;
  final String? browseId;
  final String? collectionId;
  final String type;
  final int year;
  final int? trackCount;
  final String? genre;

  const SyncContent({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.imageUrl,
    this.duration,
    required this.source,
    this.browseId,
    this.collectionId,
    this.type = 'track',
    this.year = 0,
    this.trackCount,
    this.genre,
  });

  String get dedupKey => '${title.toLowerCase().trim()}_${artist.toLowerCase().trim()}';
  String get sourcePriority {
    switch (source) {
      case 'itunes': return '01';
      case 'audius': return '02';
      case 'muzo': return '03';
      case 'jamendo': return '04';
      default: return '05';
    }
  }
}

class SyncEngine {
  static final List<SyncContent> _cache = [];
  static DateTime? _lastSync;

  static Future<void> syncAll() async {
    debugPrint('SyncEngine: starting full sync');
    final y = DateTime.now().year;
    final now = DateTime.now();

    final albums = <SyncContent>[];
    final singles = <SyncContent>[];
    final tracks = <SyncContent>[];
    final playlists = <SyncContent>[];
    final artists = <String>[];

    // ─── Albums ──────────────────────────────────────
    final albumSources = await Future.wait([
      _syncItunesAlbums(y),
      _syncCatalogAlbums('hip hop', 20),
      _syncMuzoAlbums(y),
      _syncCatalogAlbums('rap', 20),
      _syncCatalogAlbums('rnb', 20),
      _syncCatalogAlbums('pop', 20),
      _syncCatalogAlbums('afrobeat', 20),
      _syncCatalogAlbums('gospel', 20),
      _syncCatalogAlbums('trap', 20),
    ]);

    for (final batch in albumSources) {
      for (final a in batch) {
        final existing = albums.indexWhere((e) => e.dedupKey == a.dedupKey);
        if (existing >= 0) {
           if (a.sourcePriority.compareTo(albums[existing].sourcePriority) < 0) {
             albums[existing] = a;
          }
        } else {
          albums.add(a);
        }
      }
    }

    // ─── Singles & EP (from tracks with no album) ──
    final trackSources = await Future.wait([
      _syncItunesTracks(y, ['rap', 'rnb', 'pop', 'hip hop', 'afro', 'drill']),
      _syncCatalogTracks('rap 2026', 30),
      _syncCatalogTracks('rnb 2026', 30),
      _syncCatalogTracks('pop 2026', 30),
      _syncMuzoSongs('rap 2026', 30),
      _syncMuzoSongs('rnb 2026', 30),
      _syncMuzoSongs('hip hop 2026', 30),
      _syncMuzoSongs('afrobeat 2026', 30),
    ]);

    for (final batch in trackSources) {
      for (final t in batch) {
        final existing = singles.indexWhere((e) => e.dedupKey == t.dedupKey);
        if (existing >= 0) {
           if (t.sourcePriority.compareTo(singles[existing].sourcePriority) < 0) {
             singles[existing] = t;
          }
        } else {
          singles.add(t);
        }
      }
    }

    // ─── Playlists ───────────────────────────────────
    final playlistSources = await Future.wait([
      _syncCatalogPlaylists('rap francais', 15),
      _syncCatalogPlaylists('rap us', 15),
      _syncCatalogPlaylists('afro', 15),
      _syncCatalogPlaylists('amapiano', 15),
      _syncCatalogPlaylists('r&b', 15),
      _syncCatalogPlaylists('pop 2026', 15),
      _syncCatalogPlaylists('gospel', 15),
      _syncCatalogPlaylists('hip hop', 15),
      _syncCatalogPlaylists('trending', 15),
      _syncCatalogPlaylists('hits 2026', 15),
      _syncCatalogPlaylists('top rap', 15),
      _syncCatalogPlaylists('new music', 15),
    ]);

    for (final batch in playlistSources) {
      for (final p in batch) {
        final existing = playlists.indexWhere((e) => e.dedupKey == p.dedupKey);
        if (existing >= 0) {
           if (p.sourcePriority.compareTo(playlists[existing].sourcePriority) < 0) {
             playlists[existing] = p;
          }
        } else {
          playlists.add(p);
        }
      }
    }

    // ─── Artists ─────────────────────────────────────
    final artistSet = <String>{};
    for (final a in albums) if (a.artist.isNotEmpty) artistSet.add(a.artist);
    for (final s in singles) if (s.artist.isNotEmpty) artistSet.add(s.artist);
    for (final a in artistSet) artists.add(a);

    _cache.clear();
    _cache.addAll([...albums, ...singles, ...tracks, ...playlists]);
    _lastSync = now;

    debugPrint('SyncEngine: sync complete — albums:${albums.length} tracks:${singles.length} play:${playlists.length} artists:${artists.length}');
  }

  // ─── Public getters ──────────────────────────────────

  static List<SyncContent> get albums => _cache.where((c) => c.type == 'album').toList();
  static List<SyncContent> get singles => _cache.where((c) => c.type == 'track').toList();
  static List<SyncContent> get playlists => _cache.where((c) => c.type == 'playlist').toList();
  static List<String> get artists => _cache.map((c) => c.artist).where((a) => a.isNotEmpty).toSet().toList();
  static DateTime? get lastSync => _lastSync;
  static int get count => _cache.length;

  // ─── Internal sync methods ──────────────────────────

  static Future<List<SyncContent>> _syncItunesAlbums(int year) async {
    final results = <SyncContent>[];
    for (final genre in ['rap', 'rnb', 'pop', 'hip hop', 'afrobeats', 'trap', 'gospel']) {
      try {
        final list = await ItunesService.fetchAlbumsByGenre(
          '$genre album $year',
          limit: 15,
        );
        for (final a in list) {
          results.add(SyncContent(
            id: 'itunes_${a.collectionId ?? a.title.hashCode}',
            title: a.title,
            artist: a.artist,
            album: a.title,
            imageUrl: a.imageUrl,
            source: 'itunes',
            type: 'album',
            year: int.tryParse(a.year) ?? year,
            trackCount: a.trackCount,
             collectionId: a.collectionId?.toString(),
            browseId: a.browseId,
          ));
        }
      } catch (_) {}
    }
    return results;
  }

  static Future<List<SyncContent>> _syncCatalogAlbums(String query, int limit) async {
    final results = <SyncContent>[];
    try {
      final list = await MusicCatalogService.searchAlbums(query, limit: limit);
      for (final a in list) {
        results.add(SyncContent(
          id: 'catalog_${a.source}_${a.id}',
          title: a.title,
          artist: a.artist,
          album: a.title,
          imageUrl: a.imageUrl,
          source: a.source,
          type: 'album',
          year: 2026,
          trackCount: a.trackCount,
          browseId: a.id,
        ));
      }
    } catch (_) {}
    return results;
  }

  static Future<List<SyncContent>> _syncMuzoAlbums(int year) async {
    final results = <SyncContent>[];
    for (final genre in ['rap', 'rnb', 'pop', 'hip hop', 'afrobeats', 'trap']) {
      try {
        final list = await MuzoService.searchAlbumsByGenre('$genre album $year', limit: 10);
        for (final a in list) {
          results.add(SyncContent(
            id: 'muzo_album_${a.browseId ?? a.title.hashCode}',
            title: a.title,
            artist: a.artist,
            album: a.title,
            imageUrl: a.imageUrl ?? a.image,
            source: 'muzo',
            type: 'album',
            year: year,
            trackCount: a.trackCount,
            browseId: a.browseId,
          ));
        }
      } catch (_) {}
    }
    return results;
  }

  static Future<List<SyncContent>> _syncItunesTracks(int year, List<String> genres) async {
    final results = <SyncContent>[];
    for (final genre in genres) {
      try {
        final list = await ItunesService.searchTracksByQuery('$genre $year', limit: 50);
        for (final t in list) {
          results.add(SyncContent(
            id: 'itunes_track_${t.videoId}',
            title: t.title,
            artist: t.artist,
            imageUrl: t.imageUrl,
            source: 'itunes',
            type: 'track',
            year: year,
            duration: t.duration,
            genre: genre,
          ));
        }
      } catch (_) {}
    }
    return results;
  }

  static Future<List<SyncContent>> _syncMuzoSongs(String query, int limit) async {
    final results = <SyncContent>[];
    try {
      final list = await MuzoService.searchSongs(query, limit: limit);
      for (final t in list) {
        results.add(SyncContent(
          id: 'muzo_track_${t.videoId}',
          title: t.title,
          artist: t.artist,
          album: '',
          imageUrl: t.imageUrl,
          source: 'muzo',
          type: 'track',
          year: 2026,
          duration: t.duration,
        ));
      }
    } catch (_) {}
    return results;
  }

  static Future<List<SyncContent>> _syncCatalogTracks(String query, int limit) async {
    final results = <SyncContent>[];
    try {
      final list = await MusicCatalogService.searchTracks(query, limit: limit);
      for (final t in list) {
        results.add(SyncContent(
          id: 'catalog_track_${t.source}_${t.id}',
          title: t.title,
          artist: t.artist,
          album: t.albumName ?? '',
          imageUrl: t.imageUrl,
          source: t.source,
          type: 'track',
          year: 2026,
          duration: t.durationMs > 0 ? '${(t.durationMs / 60000).floor()}:${((t.durationMs % 60000) / 1000).floor().toString().padLeft(2, '0')}' : '',
        ));
      }
    } catch (_) {}
    return results;
  }

  static Future<List<SyncContent>> _syncCatalogPlaylists(String query, int limit) async {
    final results = <SyncContent>[];
    try {
      final list = await MusicCatalogService.searchPlaylists(query, limit: limit);
      for (final p in list) {
        results.add(SyncContent(
          id: 'catalog_play_${p.source}_${p.id}',
          title: p.title,
          artist: '',
          album: p.description ?? '',
          imageUrl: p.imageUrl,
          source: p.source,
          type: 'playlist',
          year: 2026,
          trackCount: p.trackCount,
          browseId: p.id,
        ));
      }
    } catch (_) {}
    return results;
  }

  // ─── Query interfaces ───────────────────────────────

  static List<SyncContent> getAlbums({String? genre, String? artist, String? year}) {
    var result = albums;
    if (genre != null) {
      result = result.where((c) =>
          c.genre != null && c.genre!.toLowerCase().contains(genre.toLowerCase())).toList();
    }
    if (artist != null) {
      final a = artist.toLowerCase();
      result = result.where((c) => c.artist.toLowerCase().contains(a)).toList();
    }
    if (year != null) {
      result = result.where((c) => c.year.toString() == year).toList();
    }
    return result;
  }

  static List<SyncContent> getSingles({String? genre, String? artist}) {
    var result = singles;
    if (genre != null) {
      result = result.where((c) =>
          c.genre != null && c.genre!.toLowerCase().contains(genre.toLowerCase())).toList();
    }
    if (artist != null) {
      final a = artist.toLowerCase();
      result = result.where((c) => c.artist.toLowerCase().contains(a)).toList();
    }
    return result;
  }

  static List<SyncContent> getPlaylists({String? genre}) {
    var result = playlists;
    if (genre != null) {
      result = result.where((c) =>
          c.album != null && c.album!.toLowerCase().contains(genre.toLowerCase())).toList();
    }
    return result;
  }

  static List<SyncContent> getTrending({int limit = 20}) {
    final sorted = [...singles]..sort((a, b) {
      final aYear = a.year;
      final bYear = b.year;
      if (aYear != bYear) return bYear.compareTo(aYear);
      return a.sourcePriority.compareTo(b.sourcePriority);
    });
    return sorted.take(limit).toList();
  }

  static List<SyncContent> getNewReleases({int daysAgo = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: daysAgo));
    return albums.where((c) {
      // We approximate by year+recent since we don't have exact dates in all cases
      return c.year >= DateTime.now().year;
    }).toList();
  }
}
