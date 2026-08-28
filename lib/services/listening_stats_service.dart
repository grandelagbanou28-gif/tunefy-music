import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:muzo/models/muzo_item.dart';

final listeningStatsProvider = Provider<ListeningStatsService>((ref) {
  return ListeningStatsService();
});

/// A single listening event persisted in Hive.
class PlayEvent {
  final String songId;
  final String title;
  final String artist;
  final String album;
  final int durationSeconds;
  final DateTime timestamp;

  PlayEvent({
    required this.songId,
    required this.title,
    required this.artist,
    required this.album,
    required this.durationSeconds,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': durationSeconds,
    'ts': timestamp.toIso8601String(),
  };

  factory PlayEvent.fromJson(Map<String, dynamic> json) => PlayEvent(
    songId: json['songId']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    artist: json['artist']?.toString() ?? '',
    album: json['album']?.toString() ?? '',
    durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
    timestamp: DateTime.tryParse(json['ts']?.toString() ?? '') ??
        DateTime.now(),
  );
}

/// Aggregated results for one ranking bucket (Top 5 / 10 / 50).
class RankedItem {
  final String name;
  final int count;
  final String? thumbnail;

  RankedItem({required this.name, required this.count, this.thumbnail});
}

class ListeningStatsService {
  static const String _boxName = 'listening_stats';
  Box? _box;
  static const int _maxEvents = 2000;

  /// Native keyword groups used to infer a genre when the metadata has none.
  static const Map<String, List<String>> _genreKeywords = {
    'Rap': ['rap', 'freestyle', 'trap'],
    'Drill': ['drill', 'dj', 'uk drill', 'french drill'],
    'Trap': ['trap', 'bando', 'plug'],
    'Afrobeat': ['afro', 'afrobeats', 'amapiano', 'highlife', 'nigerian'],
    'Hip-Hop': ['hip hop', 'hiphop', 'boombap', 'gangsta'],
    'Pop': ['pop', 'synth', 'dance'],
    'Rock': ['rock', 'metal', 'punk', 'grunge'],
    'R&B': ['rnb', 'r&b', 'soul', 'neo soul'],
    'Reggae': ['reggae', 'dancehall', 'ska'],
    'Electro': ['edm', 'house', 'techno', 'dubstep', 'trance'],
  };

  Box get _hiveBox => _box ??= Hive.box(_boxName);

  /// Emits when new listening events are recorded so the UI can refresh.
  ValueListenable<Box> get statsListenable => _hiveBox.listenable();

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    _box = Hive.box(_boxName);
  }

  List<PlayEvent> _allEvents() {
    final raw = _hiveBox.get('events', defaultValue: <dynamic>[]) as List;
    return raw
        .map(
          (e) => PlayEvent.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((e) => e.songId.isNotEmpty)
        .toList();
  }

  /// Records a completed / started play. Must be cheap and non-blocking.
  Future<void> recordPlay(MuzoItem item) async {
    final events = _allEvents();
    events.insert(
      0,
      PlayEvent(
        songId: item.videoId ?? 'unknown_${item.title}',
        title: item.title,
        artist: item.displayArtist,
        album: item.album?.name ?? '',
        durationSeconds: item.durationSeconds ?? 0,
        timestamp: DateTime.now(),
      ),
    );
    if (events.length > _maxEvents) {
      events.removeRange(_maxEvents, events.length);
    }
    await _hiveBox.put(
      'events',
      events.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> clearAll() async {
    await _hiveBox.delete('events');
  }

  List<PlayEvent> _eventsFor(DateTime start, DateTime end) {
    return _allEvents()
        .where((e) => !e.timestamp.isBefore(start) && e.timestamp.isBefore(end))
        .toList();
  }

  DateTime _startOfWeek() {
    final now = DateTime.now();
    final day = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(day.year, day.month, day.day);
  }

  DateTime _startOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _startOfYear() {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  // ── Raw statistics ────────────────────────────────────────────────────────

  int minutesFor(DateTime start, DateTime end) {
    final seconds = _eventsFor(start, end).fold<int>(
      0,
      (sum, e) => sum + max(0, e.durationSeconds),
    );
    return (seconds / 60).ceil();
  }

  int songCountFor(DateTime start, DateTime end) =>
      _eventsFor(start, end).length;

  int uniqueSongsFor(DateTime start, DateTime end) =>
      _eventsFor(start, end).map((e) => e.songId).toSet().length;

  int uniqueArtistsFor(DateTime start, DateTime end) => _eventsFor(start, end)
      .map((e) => e.artist.toLowerCase())
      .where((a) => a.isNotEmpty && a != 'unknown')
      .toSet()
      .length;

  int uniqueAlbumsFor(DateTime start, DateTime end) => _eventsFor(start, end)
      .map((e) => e.album.toLowerCase())
      .where((a) => a.isNotEmpty)
      .toSet()
      .length;

  // ── Activity buckets ──────────────────────────────────────────────────────

  int get minutesThisWeek => minutesFor(_startOfWeek(), DateTime.now());
  int get songsThisWeek => songCountFor(_startOfWeek(), DateTime.now());
  int get minutesThisMonth => minutesFor(_startOfMonth(), DateTime.now());
  int get songsThisMonth => songCountFor(_startOfMonth(), DateTime.now());
  int get minutesThisYear => minutesFor(_startOfYear(), DateTime.now());
  int get songsThisYear => songCountFor(_startOfYear(), DateTime.now());

  int get totalMinutes => minutesFor(DateTime(2000), DateTime.now());
  int get totalSongs => songCountFor(DateTime(2000), DateTime.now());
  int get totalArtists => uniqueArtistsFor(DateTime(2000), DateTime.now());
  int get totalAlbums => uniqueAlbumsFor(DateTime(2000), DateTime.now());

  // ── Ranking helpers ───────────────────────────────────────────────────────

  List<RankedItem> topSongs(int limit) {
    final map = <String, (PlayEvent, int)>{};
    for (final e in _allEvents()) {
      final key = e.songId;
      final entry = map[key];
      if (entry == null) {
        map[key] = (e, 1);
      } else {
        map[key] = (entry.$1, entry.$2 + 1);
      }
    }
    final sorted = map.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return sorted
        .take(limit)
        .map(
          (e) => RankedItem(
            name: e.$1.title,
            count: e.$2,
            thumbnail: null,
          ),
        )
        .toList();
  }

  List<RankedItem> topArtists(int limit) {
    final map = <String, (String, int)>{};
    for (final e in _allEvents()) {
      final key = e.artist.toLowerCase();
      if (key.isEmpty || key == 'unknown') continue;
      final entry = map[key];
      if (entry == null) {
        map[key] = (e.artist, 1);
      } else {
        map[key] = (entry.$1, entry.$2 + 1);
      }
    }
    final sorted = map.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return sorted
        .take(limit)
        .map((e) => RankedItem(name: e.$1, count: e.$2))
        .toList();
  }

  List<RankedItem> topAlbums(int limit) {
    final map = <String, (String, int)>{};
    for (final e in _allEvents()) {
      final key = e.album.toLowerCase();
      if (key.isEmpty) continue;
      final entry = map[key];
      if (entry == null) {
        map[key] = (e.album, 1);
      } else {
        map[key] = (entry.$1, entry.$2 + 1);
      }
    }
    final sorted = map.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return sorted
        .take(limit)
        .map((e) => RankedItem(name: e.$1, count: e.$2))
        .toList();
  }

  /// Returns top albums by number of distinct listeners (loved albums).
  List<RankedItem> topLovedAlbums(int limit) {
    final map = <String, (String, int)>{};
    for (final e in _allEvents()) {
      final key = e.album.toLowerCase();
      if (key.isEmpty) continue;
      final entry = map[key];
      if (entry == null) {
        map[key] = (e.album, 1);
      } else {
        map[key] = (entry.$1, entry.$2 + 1);
      }
    }
    final sorted = map.values.toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return sorted
        .take(limit)
        .map((e) => RankedItem(name: e.$1, count: e.$2))
        .toList();
  }

  List<RankedItem> topGenres(int limit) {
    final map = <String, int>{};
    for (final e in _allEvents()) {
      final genre = inferGenre(e.title, e.artist);
      map[genre] = (map[genre] ?? 0) + 1;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(limit)
        .map((e) => RankedItem(name: e.key, count: e.value))
        .toList();
  }

  /// Infer a genre from title/artist keywords; defaults to "Other".
  String inferGenre(String title, String artist) {
    final text = '$title $artist'.toLowerCase();
    String best = 'Other';
    int bestScore = 0;
    for (final entry in _genreKeywords.entries) {
      var score = 0;
      for (final kw in entry.value) {
        if (text.contains(kw)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = entry.key;
      }
    }
    return best;
  }

  Future<Uint8List?> renderShareCard({
    required String username,
    required int minutes,
    required int songs,
    required int artists,
    required String topArtist,
    required String topSong,
  }) async {
    // Placeholder for a real RepaintBoundary capture implemented in the UI layer.
    return null;
  }
}
