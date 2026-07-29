import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tunefy/models/home_track.dart';

class DbService {
  static const _albumsBox = 'synced_albums';
  static const _tracksBox = 'synced_tracks';
  static const _playlistsBox = 'synced_playlists';
  static const _metaBox = 'sync_meta';

  static Box? _albums;
  static Box? _tracks;
  static Box? _playlists;
  static Box? _meta;

  static Future<void> init() async {
    _albums = await Hive.openBox(_albumsBox);
    _tracks = await Hive.openBox(_tracksBox);
    _playlists = await Hive.openBox(_playlistsBox);
    _meta = await Hive.openBox(_metaBox);
  }

  static Box get albums => _albums!;
  static Box get tracks => _tracks!;
  static Box get playlists => _playlists!;
  static Box get meta => _meta!;

  static void saveAlbums(List<HomeAlbum> items) {
    final box = _albums!;
    for (final item in items) {
      final key = 'album_${item.title.toLowerCase().trim()}_${item.artist.toLowerCase().trim()}';
      box.put(key, {
        'title': item.title,
        'artist': item.artist,
        'image': item.image,
        'imageUrl': item.imageUrl,
        'year': item.year,
        'trackCount': item.trackCount,
        'collectionId': item.collectionId,
        'browseId': item.browseId,
        'syncedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    meta.put('lastAlbumSync', DateTime.now().millisecondsSinceEpoch);
  }

  static void saveTracks(List<HomeTrack> items) {
    final box = _tracks!;
    for (final item in items) {
      final key = 'track_${item.title.toLowerCase().trim()}_${item.artist.toLowerCase().trim()}';
      box.put(key, {
        'title': item.title,
        'artist': item.artist,
        'videoId': item.videoId,
        'duration': item.duration,
        'imageUrl': item.imageUrl,
        'plays': item.plays,
        'syncedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    meta.put('lastTrackSync', DateTime.now().millisecondsSinceEpoch);
  }

  static void savePlaylists(List<Map<String, dynamic>> items) {
    final box = _playlists!;
    for (final item in items) {
      final key = 'playlist_${(item['title'] ?? '').toString().toLowerCase().trim()}';
      box.put(key, {
        ...item,
        'syncedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    meta.put('lastPlaylistSync', DateTime.now().millisecondsSinceEpoch);
  }

  static List<HomeAlbum> loadAlbums() {
    final box = _albums!;
    return box.values.map((m) {
      final map = m as Map;
      return HomeAlbum(
        title: map['title'] as String? ?? '',
        artist: map['artist'] as String? ?? '',
        image: map['image'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        year: map['year'] as String? ?? '',
        trackCount: (map['trackCount'] as int?) ?? 0,
        collectionId: map['collectionId'] as int?,
        browseId: map['browseId'] as String?,
      );
    }).toList();
  }

  static List<HomeTrack> loadTracks() {
    final box = _tracks!;
    return box.values.map((m) {
      final map = m as Map;
      return HomeTrack(
        videoId: map['videoId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        artist: map['artist'] as String? ?? '',
        duration: map['duration'] as String? ?? '',
        imageUrl: map['imageUrl'] as String?,
        plays: map['plays'] as String? ?? '',
      );
    }).toList();
  }

  static DateTime lastSync(String key) {
    final ts = meta.get(key);
    if (ts is int) return DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime(2000);
  }

  static bool needsSync(String key, {int maxAgeHours = 24}) {
    final last = lastSync(key);
    return DateTime.now().difference(last).inHours > maxAgeHours;
  }
}