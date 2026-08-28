import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/services/category_curator.dart';

/// Free / keyless music sources used by the Workout category:
/// - Audius (open catalog, keyless, direct mp3 streams)
/// - Jamendo (Creative Commons catalog, client_id)
const String jamendoClientId = '5749eeec';

const _timeout = Duration(seconds: 10);

/// Audius content gateways can be flaky; this gateway is used as a stable
/// fallback host for the signed cidstream URLs (the signature is host-agnostic).
const String _audiusGateway = 'https://v.monophonic.digital';

Future<dynamic> _getJson(Uri uri) async {
  try {
    final resp = await http.get(uri).timeout(_timeout);
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} for $uri');
    }
    return jsonDecode(resp.body);
  } catch (e) {
    debugPrint('WORKOUT_REQ FAIL $uri :: $e');
    rethrow;
  }
}

/// Audius content gateway hosts change frequently and some are dead. The
/// signed URL is valid on any gateway, so we rewrite it to a known-good one.
String _audiusStreamUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  return uri.replace(
    scheme: 'https',
    host: Uri.parse(_audiusGateway).host,
    port: null,
  ).toString();
}

String _audiusArt(Map<String, dynamic>? art, String size) {
  if (art == null) return '';
  final url = (art[size] as String?) ?? '';
  if (url.isEmpty) return '';
  // Artwork is served as plain content on any gateway; rewrite the host to a
  // known-good one since Audius content hosts are frequently unreachable.
  return _audiusStreamUrl(url);
}

/// True when a workout collection title is a mix/loop/non-song upload that
/// should stay out of the curated rows (megamixes, "1 hour" loops, ...).
bool _isJunkTitle(String title) => isJunkSong(title, isAmbient: false);

/// A workout album (from Audius or Jamendo).
class WorkoutAlbum {
  const WorkoutAlbum({
    required this.name,
    required this.artist,
    required this.coverUrl,
    required this.source,
    required this.id,
  });

  final String name;
  final String artist;
  final String coverUrl;
  final String source;
  final String id;
}

/// A workout playlist (from Audius or Jamendo).
class WorkoutPlaylist {
  const WorkoutPlaylist({
    required this.name,
    required this.coverUrl,
    required this.source,
    required this.id,
  });

  final String name;
  final String coverUrl;
  final String source;
  final String id;
}

/// A workout artist (from Audius or Jamendo).
class WorkoutArtist {
  const WorkoutArtist({
    required this.name,
    required this.imageUrl,
    required this.source,
    required this.id,
  });

  final String name;
  final String imageUrl;
  final String source;
  final String id;
}

MuzoItem _muzoTrack({
  required String id,
  required String title,
  required String artist,
  required String cover,
  required String audioUrl,
  int? durationSeconds,
}) {
  return MuzoItem(
    title: title,
    thumbnails: [
      MuzoThumbnail(url: cover, width: 0, height: 0),
    ],
    resultType: 'user_track',
    isExplicit: false,
    videoId: id,
    durationSeconds: durationSeconds,
    artists: [MuzoArtist(name: artist, id: '')],
    audioUrl: audioUrl,
  );
}

// ─── Audius ───

Future<List<MuzoItem>> _audiusTracks(String query) async {
  final data = await _getJson(
    Uri.parse('https://api.audius.co/v1/tracks/search').replace(
      queryParameters: {'query': query, 'limit': '15'},
    ),
  );
  final results = (data as Map<String, dynamic>)['data'] as List? ?? [];
  final tracks = <MuzoItem>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final title = m['title'] as String?;
    if (title == null || title.isEmpty) continue;
    if (_isJunkTitle(title)) continue;
    final user = (m['user'] as Map<String, dynamic>?) ?? const {};
    final art = (m['artwork'] as Map<String, dynamic>?) ?? const {};
    final stream = (m['stream'] as Map<String, dynamic>?) ?? const {};
    final streamUrl = (stream['url'] as String?) ?? '';
    if (streamUrl.isEmpty) continue;
    final cover = _audiusArt(art, '480x480');
    tracks.add(
      _muzoTrack(
        id: 'audius_${m['id']}',
        title: title,
        artist: (user['name'] as String?) ?? '',
        cover: cover.isNotEmpty ? cover : _audiusArt(art, '150x150'),
        audioUrl: _audiusStreamUrl(streamUrl),
        durationSeconds: (m['duration'] as num?)?.toInt(),
      ),
    );
  }
  return tracks;
}

Future<List<WorkoutAlbum>> _audiusAlbums(String query) async {
  final data = await _getJson(
    Uri.parse('https://api.audius.co/v1/playlists/search').replace(
      queryParameters: {'query': query, 'type': 'album', 'limit': '10'},
    ),
  );
  final results = (data as Map<String, dynamic>)['data'] as List? ?? [];
  final albums = <WorkoutAlbum>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final name = m['playlist_name'] as String?;
    if (name == null || name.isEmpty) continue;
    if (_isJunkTitle(name)) continue;
    final img = (m['artwork'] as Map<String, dynamic>?) ?? const {};
    albums.add(
      WorkoutAlbum(
        name: name,
        artist: ((m['user'] as Map<String, dynamic>?) ?? const {})['name'] ?? '',
        coverUrl: _audiusArt(img, '480x480'),
        source: 'audius',
        id: m['id'].toString(),
      ),
    );
  }
  return albums;
}

Future<List<WorkoutPlaylist>> _audiusPlaylists(String query) async {
  final data = await _getJson(
    Uri.parse('https://api.audius.co/v1/playlists/search').replace(
      queryParameters: {'query': query, 'limit': '10'},
    ),
  );
  final results = (data as Map<String, dynamic>)['data'] as List? ?? [];
  final playlists = <WorkoutPlaylist>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final name = m['playlist_name'] as String?;
    if (name == null || name.isEmpty) continue;
    if (_isJunkTitle(name)) continue;
    final img = (m['artwork'] as Map<String, dynamic>?) ?? const {};
    playlists.add(
      WorkoutPlaylist(
        name: name,
        coverUrl: _audiusArt(img, '480x480'),
        source: 'audius',
        id: m['id'].toString(),
      ),
    );
  }
  return playlists;
}

Future<List<WorkoutArtist>> _audiusArtists(String query) async {
  final data = await _getJson(
    Uri.parse('https://api.audius.co/v1/users/search').replace(
      queryParameters: {'query': query, 'limit': '10'},
    ),
  );
  final results = (data as Map<String, dynamic>)['data'] as List? ?? [];
  final artists = <WorkoutArtist>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final name = m['name'] as String?;
    if (name == null || name.isEmpty) continue;
    final img = (m['profile_picture'] as Map<String, dynamic>?) ?? const {};
    artists.add(
      WorkoutArtist(
        name: name,
        imageUrl: _audiusArt(img, '480x480'),
        source: 'audius',
        id: m['id'].toString(),
      ),
    );
  }
  return artists;
}

Future<List<MuzoItem>> _audiusCollectionTracks(String id) async {
  final data = await _getJson(
    Uri.parse('https://api.audius.co/v1/playlists/$id/tracks'),
  );
  final results = (data as Map<String, dynamic>)['data'] as List? ?? [];
  final tracks = <MuzoItem>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final title = m['title'] as String?;
    if (title == null || title.isEmpty) continue;
    if (_isJunkTitle(title)) continue;
    final user = (m['user'] as Map<String, dynamic>?) ?? const {};
    final art = (m['artwork'] as Map<String, dynamic>?) ?? const {};
    final stream = (m['stream'] as Map<String, dynamic>?) ?? const {};
    final streamUrl = (stream['url'] as String?) ?? '';
    if (streamUrl.isEmpty) continue;
    final cover = _audiusArt(art, '480x480');
    tracks.add(
      _muzoTrack(
        id: 'audius_${m['id']}',
        title: title,
        artist: (user['name'] as String?) ?? '',
        cover: cover.isNotEmpty ? cover : _audiusArt(art, '150x150'),
        audioUrl: _audiusStreamUrl(streamUrl),
        durationSeconds: (m['duration'] as num?)?.toInt(),
      ),
    );
  }
  return tracks;
}

// ─── Jamendo ───

Future<List<MuzoItem>> _jamendoTracks(String query) async {
  final data = await _getJson(
    Uri.parse('https://api.jamendo.com/v3.0/tracks/').replace(
      queryParameters: {
        'client_id': jamendoClientId,
        'format': 'json',
        'search': query,
        'limit': '15',
      },
    ),
  );
  final results = (data as Map<String, dynamic>)['results'] as List? ?? [];
  final tracks = <MuzoItem>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final name = m['name'] as String?;
    final audio = m['audio'] as String?;
    if (name == null || name.isEmpty || audio == null || audio.isEmpty) continue;
    if (_isJunkTitle(name)) continue;
    tracks.add(
      _muzoTrack(
        id: 'jamendo_${m['id']}',
        title: name,
        artist: (m['artist_name'] as String?) ?? '',
        cover: (m['album_image'] as String?) ?? '',
        audioUrl: audio,
        durationSeconds: (m['duration'] as num?)?.toInt(),
      ),
    );
  }
  return tracks;
}

Future<List<WorkoutAlbum>> _jamendoAlbums(String query) async {
  final data = await _getJson(
    Uri.parse('https://api.jamendo.com/v3.0/albums/').replace(
      queryParameters: {
        'client_id': jamendoClientId,
        'format': 'json',
        'namesearch': query,
        'limit': '10',
      },
    ),
  );
  final results = (data as Map<String, dynamic>)['results'] as List? ?? [];
  final albums = <WorkoutAlbum>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final name = m['name'] as String?;
    if (name == null || name.isEmpty) continue;
    if (_isJunkTitle(name)) continue;
    albums.add(
      WorkoutAlbum(
        name: name,
        artist: (m['artist_name'] as String?) ?? '',
        coverUrl: (m['image'] as String?) ?? '',
        source: 'jamendo',
        id: m['id'].toString(),
      ),
    );
  }
  return albums;
}

Future<List<WorkoutPlaylist>> _jamendoPlaylists(String query) async {
  final data = await _getJson(
    Uri.parse('https://api.jamendo.com/v3.0/playlists/').replace(
      queryParameters: {
        'client_id': jamendoClientId,
        'format': 'json',
        'namesearch': query,
        'limit': '10',
      },
    ),
  );
  final results = (data as Map<String, dynamic>)['results'] as List? ?? [];
  final playlists = <WorkoutPlaylist>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final name = m['name'] as String?;
    if (name == null || name.isEmpty) continue;
    if (_isJunkTitle(name)) continue;
    final img = (m['image'] as String?) ?? '';
    playlists.add(
      WorkoutPlaylist(
        name: name,
        coverUrl: img.isNotEmpty
            ? img
            : 'https://usercontent.jamendo.com?type=playlist&id=${m['id']}&width=300',
        source: 'jamendo',
        id: m['id'].toString(),
      ),
    );
  }
  return playlists;
}

Future<List<WorkoutArtist>> _jamendoArtists(String query) async {
  final data = await _getJson(
    Uri.parse('https://api.jamendo.com/v3.0/artists/').replace(
      queryParameters: {
        'client_id': jamendoClientId,
        'format': 'json',
        'search': query,
        'limit': '10',
        'hasimage': 'true',
      },
    ),
  );
  final results = (data as Map<String, dynamic>)['results'] as List? ?? [];
  final artists = <WorkoutArtist>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final name = m['name'] as String?;
    if (name == null || name.isEmpty) continue;
    artists.add(
      WorkoutArtist(
        name: name,
        imageUrl: (m['image'] as String?) ?? '',
        source: 'jamendo',
        id: m['id'].toString(),
      ),
    );
  }
  return artists;
}

Future<List<MuzoItem>> _jamendoCollectionTracks(
  String type,
  String id,
) async {
  final uri = Uri.parse(
    type == 'album'
        ? 'https://api.jamendo.com/v3.0/tracks/'
        : 'https://api.jamendo.com/v3.0/playlists/tracks/',
  );
  final data = await _getJson(uri.replace(
    queryParameters: {
      'client_id': jamendoClientId,
      'format': 'json',
      if (type == 'album') 'album_id': id else 'id': id,
      'limit': '30',
    },
  ));
  final results = (data as Map<String, dynamic>)['results'] as List? ?? [];
  final tracks = <MuzoItem>[];
  for (final r in results) {
    final m = r as Map<String, dynamic>;
    final name = m['name'] as String?;
    final audio = m['audio'] as String?;
    if (name == null || name.isEmpty || audio == null || audio.isEmpty) continue;
    if (_isJunkTitle(name)) continue;
    tracks.add(
      _muzoTrack(
        id: 'jamendo_${m['id']}',
        title: name,
        artist: (m['artist_name'] as String?) ?? '',
        cover: (m['album_image'] as String?) ?? (m['image'] as String?) ?? '',
        audioUrl: audio,
        durationSeconds: (m['duration'] as num?)?.toInt(),
      ),
    );
  }
  return tracks;
}

// ─── Providers ───

/// Combined playable tracks for a workout query (Audius + Jamendo).
final workoutSongsProvider = FutureProvider.autoDispose
    .family<List<MuzoItem>, String>((ref, query) async {
  final futures = <Future<List<MuzoItem>>>[
    _audiusTracks(query).catchError((_) => <MuzoItem>[]),
    _jamendoTracks(query).catchError((_) => <MuzoItem>[]),
  ];
  final results = await Future.wait(futures);
  debugPrint(
      'WORKOUT songs "$query" -> audius=${results[0].length} jamendo=${results[1].length}');
  return dedupeMuzoSongs([...results[0], ...results[1]]);
});

/// Combined albums for a workout query (Audius + Jamendo).
final workoutAlbumsProvider = FutureProvider.autoDispose
    .family<List<WorkoutAlbum>, String>((ref, query) async {
  final futures = <Future<List<WorkoutAlbum>>>[
    _audiusAlbums(query).catchError((_) => <WorkoutAlbum>[]),
    _jamendoAlbums(query).catchError((_) => <WorkoutAlbum>[]),
  ];
  final results = await Future.wait(futures);
  debugPrint(
      'WORKOUT albums "$query" -> audius=${results[0].length} jamendo=${results[1].length}');
  return [...results[0], ...results[1]];
});

/// Combined playlists for a workout query (Audius + Jamendo).
final workoutPlaylistsProvider = FutureProvider.autoDispose
    .family<List<WorkoutPlaylist>, String>((ref, query) async {
  final futures = <Future<List<WorkoutPlaylist>>>[
    _audiusPlaylists(query).catchError((_) => <WorkoutPlaylist>[]),
    _jamendoPlaylists(query).catchError((_) => <WorkoutPlaylist>[]),
  ];
  final results = await Future.wait(futures);
  debugPrint(
      'WORKOUT playlists "$query" -> audius=${results[0].length} jamendo=${results[1].length}');
  return [...results[0], ...results[1]];
});

/// Combined artists for a workout query (Audius + Jamendo).
final workoutArtistsProvider = FutureProvider.autoDispose
    .family<List<WorkoutArtist>, String>((ref, query) async {
  final futures = <Future<List<WorkoutArtist>>>[
    _audiusArtists(query).catchError((_) => <WorkoutArtist>[]),
    _jamendoArtists(query).catchError((_) => <WorkoutArtist>[]),
  ];
  final results = await Future.wait(futures);
  debugPrint(
      'WORKOUT artists "$query" -> audius=${results[0].length} jamendo=${results[1].length}');
  return [...results[0], ...results[1]];
});

/// Tracks inside a specific album/playlist. [source] is 'audius' or
/// 'jamendo'; [type] is 'album' or 'playlist' (Jamendo only).
final workoutCollectionTracksProvider = FutureProvider.autoDispose
    .family<List<MuzoItem>, ({String source, String type, String id})>(
        (ref, arg) async {
  if (arg.source == 'audius') {
    return _audiusCollectionTracks(arg.id).catchError((_) => <MuzoItem>[]);
  }
  return _jamendoCollectionTracks(arg.type, arg.id)
      .catchError((_) => <MuzoItem>[]);
});
