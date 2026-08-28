import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/utils/api_constants.dart';

/// A single track from the Jamendo API (free, Creative-Commons music).
class JamendoTrack {
  final String id;
  final String name;
  final String artistName;
  final String albumName;
  final String audioUrl;
  final String imageUrl;
  final int? durationSeconds;

  const JamendoTrack({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumName,
    required this.audioUrl,
    required this.imageUrl,
    this.durationSeconds,
  });

  factory JamendoTrack.fromJson(Map<String, dynamic> json) {
    return JamendoTrack(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      artistName: json['artist_name']?.toString() ?? '',
      albumName: json['album_name']?.toString() ?? '',
      audioUrl: json['audio']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? '',
      durationSeconds: (json['duration'] as num?)?.toInt(),
    );
  }

  /// A Jamendo track maps to a directly-playable item: resultType
  /// 'user_track' makes the audio handler stream [audioUrl] straight away
  /// instead of trying to resolve a YouTube video id.
  MuzoItem toMuzoItem() {
    return MuzoItem(
      title: name,
      thumbnails: imageUrl.isNotEmpty
          ? [MuzoThumbnail(url: imageUrl, width: 300, height: 300)]
          : const [],
      resultType: 'user_track',
      isExplicit: false,
      videoId: id,
      durationSeconds: durationSeconds,
      artists: [MuzoArtist(name: artistName, id: null)],
      album: albumName.isNotEmpty ? MuzoAlbum(name: albumName, id: '') : null,
      audioUrl: audioUrl,
    );
  }
}

/// Keyless-minimal Jamendo client. Every method returns an empty list on any
/// failure so callers can fall through to the next source without try/catch.
class JamendoApiService {
  static const String _base = 'https://api.jamendo.com/v3.0';
  static const Duration _timeout = Duration(seconds: 8);
  final http.Client _client = http.Client();

  Map<String, String> _q(Map<String, String> params) => {
        'client_id': ApiConstants.jamendoClientId,
        'format': 'json',
        ...params,
      };

  Future<List<JamendoTrack>> _fetch(
    String method,
    Map<String, String> params,
  ) async {
    try {
      final uri = Uri.parse('$_base/$method').replace(
        queryParameters: _q(params),
      );
      final res = await _client
          .get(uri, headers: const {'User-Agent': 'Tunefy/3.9.0 (Android)'})
          .timeout(_timeout);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final headers = body['headers'];
      if (headers is Map && headers['status'] != 'success') return [];
      final results = body['results'] as List? ?? const [];
      return results
          .map((e) => JamendoTrack.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Full-text search across track/album/artist names.
  Future<List<JamendoTrack>> searchTracks(String query, {int limit = 10}) {
    return _fetch('tracks', {'search': query, 'limit': '$limit'});
  }

  /// Tracks tagged with a genre tag (e.g. "christian", "pop", "hiphop").
  Future<List<JamendoTrack>> tracksByTag(String tag, {int limit = 10}) {
    return _fetch('tracks', {'tags': tag, 'limit': '$limit'});
  }

  /// Every track of one album (for full-album playback).
  Future<List<JamendoTrack>> albumTracks(String albumId) {
    return _fetch('tracks', {'album_id': albumId, 'limit': '50'});
  }
}

final jamendoApiServiceProvider = Provider<JamendoApiService>((ref) {
  return JamendoApiService();
});

/// Maps a category/sub-category term to a Jamendo genre tag, or null when no
/// genre mapping exists. Used to fill sections with reliable genre music
/// before falling back to the YouTube backend.
String? jamendoTagFor(String query) {
  final q = query.trim().toLowerCase();
  const map = <String, String>{
    'gospel': 'christian',
    'christian': 'christian',
    'praise': 'christian',
    'worship': 'worship',
    'pop': 'pop',
    'hip-hop': 'hiphop',
    'hip hop': 'hiphop',
    'rap': 'hiphop',
    'rock': 'rock',
    'metal': 'metal',
    'latin': 'latin',
    'folk': 'folk',
    'country': 'country',
    'jazz': 'jazz',
    'blues': 'blues',
    'classical': 'classical',
    'electronic': 'electronic',
    'dance': 'electronic',
    'edm': 'electronic',
    'reggae': 'reggae',
    'soul': 'soul',
    'rnb': 'rnb',
    'workout': 'sport',
    'ambient': 'ambient',
    'chill': 'chill',
    'relax': 'chill',
    'meditation': 'ambient',
    'afro': 'africa',
    'afrobeats': 'africa',
    'new age': 'newage',
  };
  for (final entry in map.entries) {
    if (q.contains(entry.key)) return entry.value;
  }
  return null;
}
