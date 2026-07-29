import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:tunefy/models/home_track.dart';
import 'package:tunefy/services/server_config_service.dart';
import 'package:tunefy/services/muzo_service.dart';

enum SearchFilter { songs, albums, artists, playlists, all }

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String? imageUrl;
  final String? duration;
  final String? videoId;
  final String? browseId;
  final String? saavnId;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.imageUrl,
    this.duration,
    this.videoId,
    this.browseId,
    this.saavnId,
  });
}

class SearchSuggestion {
  final String query;
  const SearchSuggestion({required this.query});
}

class ArtistInfo {
  final String name;
  final String? channelId;
  final String? imageUrl;

  const ArtistInfo({required this.name, this.channelId, this.imageUrl});
}

class SearchService {
  static const String _ytMusicUrl = 'https://music.youtube.com/youtubei/v1';
  static const String _ytUrl = 'https://www.youtube.com/youtubei/v1';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
  static const String _ytApiKey = 'AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8';
  static String get _saavnUrl => ServerConfigService.muzoBackendUrl;

  static Map<String, String> _getMusicHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'com.google.android.apps.youtube.music/7.27.52 (Linux; U; Android 14; en_US; sdk_gphone64_x86_64 Build/UE1A.230829.036.A1) gzip',
      'X-Goog-Api-Key': _apiKey,
    };
  }

  static Map<String, dynamic> _getMusicContext() {
    return {
      'context': {
        'client': {
          'clientName': 'ANDROID_MUSIC',
          'clientVersion': '7.27.52',
          'androidSdkVersion': 34,
          'hl': 'en',
          'gl': 'US',
          'osName': 'Android',
          'osVersion': '14',
          'deviceMake': 'Google',
          'deviceModel': 'sdk_gphone64_x86_64',
        },
      },
    };
  }

  static Map<String, dynamic> _getWebContext() {
    return {
      'context': {
        'client': {
          'clientName': 'WEB',
          'clientVersion': '2.20241022.01.00',
          'hl': 'en',
          'gl': 'US',
        },
      },
    };
  }

  static Future<List<SearchResult>> search(String query, {SearchFilter filter = SearchFilter.all, int limit = 300}) async {
    if (query.trim().isEmpty) return [];

    // Muzo primary for songs & albums (real YouTube videoIds / browseIds)
    if (filter == SearchFilter.all || filter == SearchFilter.songs) {
      try {
        final muzoSongs = await _searchMuzoSongs(query, limit);
        if (muzoSongs.isNotEmpty) {
          if (filter == SearchFilter.songs) return muzoSongs;
        }
      } catch (_) {}
    }
    if (filter == SearchFilter.all || filter == SearchFilter.albums) {
      try {
        final muzoAlbums = await _searchMuzoAlbums(query, limit);
        if (muzoAlbums.isNotEmpty) {
          if (filter == SearchFilter.albums) return muzoAlbums;
        }
      } catch (_) {}
    }

    // Fallback to Saavn + YouTube
    try {
      if (filter == SearchFilter.all) {
        return await _searchSaavnAll(query, limit);
      }
      return await _searchSaavnByType(query, filter, limit);
    } catch (e) {
      debugPrint('SearchService: Saavn search failed, falling back to YT: $e');
    }

    return _searchYouTubeFallback(query, filter, limit);
  }

  static Future<List<SearchResult>> _searchMuzoSongs(String query, int limit) async {
    final tracks = await MuzoService.searchSongs(query, limit: limit);
    return tracks.map((t) => SearchResult(
      id: t.videoId,
      title: t.title,
      subtitle: t.artist,
      type: 'song',
      imageUrl: t.imageUrl,
      videoId: t.videoId,
      duration: t.duration,
    )).toList();
  }

  static Future<List<SearchResult>> _searchMuzoAlbums(String query, int limit) async {
    final albums = await MuzoService.searchAlbumsByGenre(query, limit: limit);
    return albums.map((a) => SearchResult(
      id: a.browseId ?? a.title.hashCode.toString(),
      title: a.title,
      subtitle: a.artist,
      type: 'album',
      imageUrl: a.imageUrl ?? a.image,
      browseId: a.browseId,
    )).toList();
  }

  static Future<List<SearchResult>> _searchSaavnAll(String query, int limit) async {
    final songF = _saavnSearch(query, 'songs', 100);
    final albumF = _saavnSearch(query, 'albums', 50);
    final playlistF = _saavnSearch(query, 'playlists', 50);
    final artistF = _saavnSearch(query, 'artists', 25);

    final results = await Future.wait([songF, albumF, playlistF, artistF]);
    final songs = results[0];
    final albums = results[1];
    final playlists = results[2];
    final artists = results[3];

    debugPrint('SearchService: Saavn results — songs:${songs.length} albums:${albums.length} playlists:${playlists.length} artists:${artists.length}');

    final seen = <String>{};
    final merged = <SearchResult>[];

    void add(List<SearchResult> src, int max) {
      int count = 0;
      for (final r in src) {
        if (merged.length >= limit) return;
        if (count >= max) continue;
        if (seen.add(r.id)) { merged.add(r); count++; }
      }
    }

    add(songs, 100);
    add(albums, 50);
    add(playlists, 50);
    add(artists, 25);

    for (final r in [...songs, ...albums, ...playlists, ...artists]) {
      if (merged.length >= limit) break;
      if (seen.add(r.id)) merged.add(r);
    }

    return merged;
  }

  static Future<List<SearchResult>> _searchSaavnByType(String query, SearchFilter filter, int limit) async {
    final saavnType = switch (filter) {
      SearchFilter.songs => 'songs',
      SearchFilter.albums => 'albums',
      SearchFilter.artists => 'artists',
      SearchFilter.playlists => 'playlists',
      SearchFilter.all => 'songs',
    };
    return _saavnSearch(query, saavnType, limit);
  }

  static Future<List<SearchResult>> _saavnSearch(String query, String type, int limit) async {
    final paths = [
      '$_saavnUrl/api/jiosaavn/search/$type',
      '$_saavnUrl/search/$type',
      '$_saavnUrl/jiosaavn/search/$type',
    ];

    for (final basePath in paths) {
      try {
        final uri = Uri.parse(basePath).replace(queryParameters: {'query': query, 'limit': limit.toString()});
        final response = await http.get(uri).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final results = _parseSaavnResponse(data, type);
          if (results.isNotEmpty) return results.take(limit).toList();
        }
      } catch (_) {}
    }

    try {
      final uri = Uri.parse('$_saavnUrl/api.php').replace(queryParameters: {
        '__call': 'search.getResults',
        'query': query,
        'n': limit.toString(),
        'p': '1',
        'includeMetaTags': '1',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = _parseSaavnLegacyResponse(data, type);
        if (results.isNotEmpty) return results.take(limit).toList();
      }
    } catch (_) {}

    return [];
  }

  static List<SearchResult> _parseSaavnResponse(dynamic data, String type) {
    final List<SearchResult> results = [];
    try {
      dynamic items;
      if (data is Map) {
        items = data['results'] ?? data['data']?['results'] ?? data['data'];
        if (items is Map) items = items['results'];
      }
      if (items == null || items is! List) return results;

      for (final item in items) {
        if (item is! Map) continue;
        final result = _parseSaavnItem(item, type);
        if (result != null) results.add(result);
      }
    } catch (e) {
      debugPrint('SearchService: _parseSaavnResponse error: $e');
    }
    return results;
  }

  static List<SearchResult> _parseSaavnLegacyResponse(dynamic data, String type) {
    final List<SearchResult> results = [];
    try {
      final items = data['results'] ?? [];
      for (final item in items) {
        if (item is! Map) continue;
        final result = _parseSaavnItem(item, type);
        if (result != null) results.add(result);
      }
    } catch (_) {}
    return results;
  }

  static SearchResult? _parseSaavnItem(dynamic item, String type) {
    try {
      final id = (item['id'] ?? item['encrypted_media_id'] ?? '').toString();
      if (id.isEmpty) return null;

      final title = (item['title'] ?? item['name'] ?? '').toString();
      if (title.isEmpty) return null;

      final subtitle = (item['subtitle'] ?? item['description'] ?? item['artist'] ?? item['singers'] ?? '').toString();

      String? imageUrl;
      final image = item['image'];
      if (image is List && image.isNotEmpty) {
        final last = image.last;
        if (last is Map) imageUrl = last['url']?.toString();
        else imageUrl = last?.toString();
      } else if (image is String) {
        imageUrl = image;
      }
      final thumb = item['thumbnail'];
      if (imageUrl == null && thumb is List && thumb.isNotEmpty) {
        final last = thumb.last;
        if (last is Map) imageUrl = last['url']?.toString();
        else imageUrl = last?.toString();
      }

      String itemType = type;
      if (item['type'] == 'song' || item['type'] == 'track') itemType = 'song';
      else if (item['type'] == 'album') itemType = 'album';
      else if (item['type'] == 'artist') itemType = 'artist';
      else if (item['type'] == 'playlist') itemType = 'playlist';

      final duration = item['duration'] ?? item['duration_secs'];
      final durationStr = duration != null ? _formatDuration(duration is int ? duration : int.tryParse(duration.toString()) ?? 0) : null;

      final saavnUrl = (item['url'] ?? '').toString();

      return SearchResult(
        id: 'saavn_$id',
        title: title,
        subtitle: subtitle,
        type: itemType,
        imageUrl: imageUrl is String ? imageUrl : null,
        duration: durationStr,
        browseId: saavnUrl.isNotEmpty ? saavnUrl : null,
        saavnId: id,
      );
    } catch (e) {
      return null;
    }
  }

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static Future<List<HomeTrack>> fetchSaavnAlbumTracks(String albumId) async {
    final paths = [
      '$_saavnUrl/api/jiosaavn/albums?id=$albumId',
      '$_saavnUrl/albums?id=$albumId',
      '$_saavnUrl/jiosaavn/album/$albumId',
    ];

    for (final url in paths) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return _parseSaavnTracksFromResponse(data);
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<List<HomeTrack>> fetchSaavnPlaylistTracks(String playlistId) async {
    final paths = [
      '$_saavnUrl/api/jiosaavn/playlists?id=$playlistId',
      '$_saavnUrl/playlists?id=$playlistId',
      '$_saavnUrl/jiosaavn/playlist/$playlistId',
    ];

    for (final url in paths) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return _parseSaavnTracksFromResponse(data);
        }
      } catch (_) {}
    }
    return [];
  }

  static Future<List<HomeTrack>> fetchSaavnArtistTracks(String artistId) async {
    final paths = [
      '$_saavnUrl/api/jiosaavn/artists/$artistId/songs',
      '$_saavnUrl/artists/$artistId/songs',
      '$_saavnUrl/jiosaavn/artists/$artistId/songs',
    ];

    for (final url in paths) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return _parseSaavnTracksFromResponse(data);
        }
      } catch (_) {}
    }
    return [];
  }

  static List<HomeTrack> _parseSaavnTracksFromResponse(dynamic data) {
    final List<HomeTrack> tracks = [];
    try {
      dynamic songsList;
      if (data is Map) {
        songsList = data['songs'] ?? data['data']?['songs'] ?? data['tracks'];
        if (songsList is Map) songsList = songsList['list'] ?? songsList['songs'];
        songsList ??= data['data'];
        if (songsList is Map) songsList = null;
      }
      if (songsList == null || songsList is! List) return tracks;

      for (final item in songsList) {
        if (item is! Map) continue;
        final id = (item['id'] ?? item['encrypted_media_id'] ?? '').toString();
        final title = (item['title'] ?? '').toString();
        final artist = (item['artist'] ?? item['singers'] ?? item['subtitle'] ?? '').toString();
        if (id.isEmpty || title.isEmpty) continue;

        String? imageUrl;
        final image = item['image'];
        if (image is List && image.isNotEmpty) {
          final last = image.last;
          if (last is Map) imageUrl = last['url']?.toString();
          else imageUrl = last?.toString();
        }

        tracks.add(HomeTrack(
          videoId: 'deezer_$id',
          title: title,
          artist: artist,
          imageUrl: imageUrl,
          duration: item['duration']?.toString() ?? '0',
        ));
      }
    } catch (e) {
      debugPrint('SearchService: _parseSaavnTracksFromResponse error: $e');
    }
    return tracks;
  }

  static Future<List<SearchResult>> _searchYouTubeFallback(String query, SearchFilter filter, int limit) async {
    final musicF = _searchMusicApi(query, filter, limit);
    final webF = _searchYouTubeWeb(query, filter, limit);
    final results = await Future.wait([musicF, webF]);
    final seen = <String>{};
    final merged = <SearchResult>[];
    for (final batch in results) {
      for (final r in batch) {
        if (merged.length >= limit) break;
        if (seen.add(r.id)) merged.add(r);
      }
    }
    return merged;
  }

  static Future<ArtistInfo?> getArtistInfo(String artistName) async {
    try {
      final payload = {..._getWebContext(), 'query': artistName};
      final response = await http.post(
        Uri.parse('$_ytUrl/search?key=$_ytApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contents = data['contents']['twoColumnSearchResultsRenderer']['primaryContents']['sectionListRenderer']['contents'][0]['itemSectionRenderer']['contents'];
        for (var item in contents) {
          if (item.containsKey('channelRenderer')) {
            final cr = item['channelRenderer'];
            final title = cr['title']?['runs']?[0]?['text'] ?? '';
            final channelId = cr['channelId'];
            String? imageUrl;
            final thumbnails = cr['thumbnail']?['thumbnails'];
            if (thumbnails != null && thumbnails.isNotEmpty) {
              imageUrl = thumbnails.last['url'];
            }
            if (title.isNotEmpty && channelId != null) {
              return ArtistInfo(name: title, channelId: channelId, imageUrl: imageUrl);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SearchService: getArtistInfo error: $e');
    }
    return null;
  }

  static Future<List<SearchResult>> getArtistSongs(String artistName, {int limit = 80}) async {
    final artistInfo = await getArtistInfo(artistName);
    final channelName = artistInfo?.name ?? artistName;

    final Set<String> seenIds = {};
    final List<SearchResult> allTracks = [];

    final queries = [
      artistName,
      '$artistName official video',
      '$artistName music',
      '$artistName clip officiel',
      '$artistName feat',
      '$artistName album',
      '${artistName} ${DateTime.now().year}',
      '${artistName} ${DateTime.now().year - 1}',
      '${artistName} ${DateTime.now().year - 2}',
      '$artistName live',
      '$artistName acoustic',
      '$artistName remix',
      '$artistName ft',
      '$artistName official audio',
      '$artistName lyrics',
      '$artistName best',
      '$artistName hits',
    ];

    Future<List<SearchResult>> searchQuery(String q) async {
      try {
        final payload = {..._getWebContext(), 'query': q};
        final response = await http.post(
          Uri.parse('$_ytUrl/search?key=$_ytApiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final contents = data['contents']['twoColumnSearchResultsRenderer']['primaryContents']['sectionListRenderer']['contents'][0]['itemSectionRenderer']['contents'];
          final List<SearchResult> results = [];
          for (var item in contents) {
            if (item.containsKey('videoRenderer')) {
              final result = _parseVideoRenderer(item['videoRenderer']);
              if (result != null && result.videoId != null) {
                if (_matchesChannelName(result.subtitle, channelName)) {
                  results.add(result);
                }
              }
            }
          }
          return results;
        }
      } catch (e) {
        debugPrint('SearchService: getArtistSongs query "$q" error: $e');
      }
      return [];
    }

    final batchSize = 4;
    for (var i = 0; i < queries.length; i += batchSize) {
      if (allTracks.length >= limit) break;
      final batch = queries.sublist(i, (i + batchSize).clamp(0, queries.length));
      final batchResults = await Future.wait(batch.map(searchQuery));
      for (final results in batchResults) {
        for (final r in results) {
          if (allTracks.length >= limit) break;
          if (!seenIds.contains(r.videoId)) {
            seenIds.add(r.videoId!);
            allTracks.add(r);
          }
        }
      }
    }

    return allTracks;
  }

  static bool _matchesChannelName(String channelName, String artistName) {
    final c = channelName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final a = artistName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (c.contains(a) || a.contains(c)) return true;
    if (c.length > 3 && a.length > 3) {
      return c.startsWith(a.substring(0, a.length ~/ 2)) || a.startsWith(c.substring(0, c.length ~/ 2));
    }
    return false;
  }

  static Future<List<SearchResult>> _searchMusicApi(String query, SearchFilter filter, int limit) async {
    try {
      final payload = {..._getMusicContext(), 'query': query};
      final response = await http.post(
        Uri.parse('$_ytMusicUrl/search?prettyPrint=false'),
        headers: _getMusicHeaders(),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allResults = _parseMusicSearchResults(data, 200);
        final filtered = _filterResults(allResults, filter);
        return filtered.take(limit).toList();
      }
    } catch (e) {
      debugPrint('SearchService: Music API error for "$query": $e');
    }
    return [];
  }

  static Future<List<SearchResult>> _searchYouTubeWeb(String query, SearchFilter filter, int limit) async {
    try {
      final payload = {..._getWebContext(), 'query': query};
      final response = await http.post(
        Uri.parse('$_ytUrl/search?key=$_ytApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allResults = _parseYouTubeSearchResults(data, 200);
        final filtered = _filterResults(allResults, filter);
        return filtered.take(limit).toList();
      }
    } catch (e) {
      debugPrint('SearchService: YouTube WEB error for "$query": $e');
    }
    return [];
  }

  static List<SearchResult> _filterResults(List<SearchResult> results, SearchFilter filter) {
    if (filter == SearchFilter.all) return results;
    switch (filter) {
      case SearchFilter.songs:
        return results.where((r) => r.type == 'song').toList();
      case SearchFilter.albums:
        return results.where((r) => r.type == 'album').toList();
      case SearchFilter.artists:
        return results.where((r) => r.type == 'artist').toList();
      case SearchFilter.playlists:
        return results.where((r) => r.type == 'playlist').toList();
      default:
        return results;
    }
  }

  static List<SearchResult> _parseYouTubeSearchResults(dynamic data, int limit) {
    final List<SearchResult> results = [];
    try {
      final contents = data['contents']['twoColumnSearchResultsRenderer']['primaryContents']['sectionListRenderer']['contents'];
      for (var section in contents) {
        if (results.length >= limit) break;
        if (section.containsKey('itemSectionRenderer')) {
          final items = section['itemSectionRenderer']['contents'] ?? [];
          for (var item in items) {
            if (results.length >= limit) break;
            if (item.containsKey('videoRenderer')) {
              final result = _parseVideoRenderer(item['videoRenderer']);
              if (result != null) results.add(result);
            } else if (item.containsKey('channelRenderer')) {
              final result = _parseChannelRenderer(item['channelRenderer']);
              if (result != null) results.add(result);
            } else if (item.containsKey('lockupViewModel')) {
              final result = _parseLockupViewModel(item['lockupViewModel']);
              if (result != null) results.add(result);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SearchService: YouTube parse error: $e');
    }
    return results;
  }

  static SearchResult? _parseVideoRenderer(dynamic vr) {
    try {
      final videoId = vr['videoId'];
      final title = vr['title']?['runs']?[0]?['text'] ?? '';
      if (title.isEmpty || videoId == null) return null;

      final channel = vr['ownerText']?['runs']?[0]?['text'] ?? '';
      final length = vr['lengthText']?['simpleText'] ?? '';

      String? imageUrl;
      final thumbnails = vr['thumbnail']?['thumbnails'];
      if (thumbnails != null && thumbnails.isNotEmpty) {
        imageUrl = thumbnails.last['url'];
      }

      return SearchResult(
        id: videoId,
        title: title,
        subtitle: channel,
        type: 'song',
        imageUrl: imageUrl,
        duration: length,
        videoId: videoId,
      );
    } catch (e) {
      return null;
    }
  }

  static SearchResult? _parseChannelRenderer(dynamic cr) {
    try {
      final channelId = cr['channelId'];
      final title = cr['title']?['runs']?[0]?['text'] ?? '';
      if (title.isEmpty || channelId == null) return null;

      String? imageUrl;
      final thumbnails = cr['thumbnail']?['thumbnails'];
      if (thumbnails != null && thumbnails.isNotEmpty) {
        imageUrl = thumbnails.last['url'];
      }

      return SearchResult(
        id: channelId,
        title: title,
        subtitle: cr['subscriberCountText']?['simpleText'] ?? '',
        type: 'artist',
        imageUrl: imageUrl,
        browseId: channelId,
      );
    } catch (e) {
      return null;
    }
  }

  static SearchResult? _parseLockupViewModel(dynamic lvm) {
    try {
      final metadata = lvm['metadata']?['lockupMetadataViewModel'];
      if (metadata == null) return null;

      final title = metadata['title']?['content'] ?? '';
      if (title.isEmpty) return null;

      String subtitle = metadata['description']?['content'] ?? '';

      if (subtitle.isEmpty) {
        try {
          final metaMeta = metadata['metadata']?['contentMetadataViewModel'];
          final rows = metaMeta?['metadataRows'];
          if (rows != null && rows is List) {
            final parts = <String>[];
            for (final row in rows) {
              if (row is Map && row.containsKey('metadataParts')) {
                final mp = row['metadataParts'];
                if (mp != null && mp is List) {
                  for (final part in mp) {
                    if (part is Map && part['text'] != null) {
                      final t = part['text']['content'] ?? part['text'] ?? '';
                      if (t.toString().isNotEmpty) parts.add(t.toString());
                    }
                  }
                }
              }
            }
            subtitle = parts.join(' ');
          }
        } catch (_) {}
      }

      final contentId = lvm['contentId'] ?? '';

      String? imageUrl;
      final contentImage = lvm['contentImage'];
      if (contentImage != null) {
        try {
          final sources = contentImage['collectionThumbnailViewModel']?['primaryThumbnail']?['thumbnailViewModel']?['image']?['sources'];
          if (sources is String && sources.isNotEmpty) {
            imageUrl = sources;
          } else if (sources is List && sources.isNotEmpty) {
            imageUrl = sources[0]['url'];
          }
        } catch (_) {}
      }
      if (imageUrl == null) {
        final image = lvm['image'];
        if (image != null) {
          try {
            final sources = image['sources'];
            if (sources is List && sources.isNotEmpty) {
              imageUrl = sources[0]['url'];
            } else if (sources is String && sources.isNotEmpty) {
              imageUrl = sources;
            }
          } catch (_) {}
        }
      }

      final lowerTitle = title.toLowerCase();
      final lowerSub = subtitle.toLowerCase();
      final allText = '$lowerTitle $lowerSub';

      String contentType = lvm['contentType'] ?? '';

      String type = 'playlist';
      if (contentType == 'LOCKUP_CONTENT_TYPE_ALBUM' || contentId.startsWith('MPREb')) {
        type = 'album';
      } else if (contentId.startsWith('PL') || contentId.startsWith('VLPL')) {
        final hasAlbumKeyword = allText.contains('album') ||
            allText.contains('full album') ||
            allText.contains('ep ') ||
            allText.contains(' ep') ||
            allText.contains(' mixtape') ||
            allText.contains('studio album');
        type = hasAlbumKeyword ? 'album' : 'playlist';
      } else if (contentType == 'LOCKUP_CONTENT_TYPE_PLAYLIST') {
        type = 'playlist';
      }

      return SearchResult(
        id: contentId,
        title: title,
        subtitle: subtitle,
        type: type,
        imageUrl: imageUrl,
        browseId: contentId,
      );
    } catch (e) {
      return null;
    }
  }

  static List<SearchResult> _parseMusicSearchResults(dynamic data, int limit) {
    final List<SearchResult> results = [];
    try {
      final contents = data['contents']['tabbedSearchResultsRenderer']['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents'];
      for (var section in contents) {
        if (results.length >= limit) break;
        if (section.containsKey('itemSectionRenderer')) {
          final sectionContents = section['itemSectionRenderer']['contents'] ?? [];
          for (var item in sectionContents) {
            if (results.length >= limit) break;
            if (item.containsKey('elementRenderer')) {
              final result = _parseElementItem(item['elementRenderer']);
              if (result != null) results.add(result);
            }
          }
        }
        if (section.containsKey('musicShelfRenderer')) {
          final items = section['musicShelfRenderer']['contents'] ?? [];
          for (var item in items) {
            if (results.length >= limit) break;
            if (item.containsKey('musicResponsiveListItemRenderer')) {
              final result = _parseMusicItem(item['musicResponsiveListItemRenderer']);
              if (result != null) results.add(result);
            }
          }
        }
        if (section.containsKey('musicCarouselShelfRenderer')) {
          final items = section['musicCarouselShelfRenderer']['contents'] ?? [];
          for (var item in items) {
            if (results.length >= limit) break;
            if (item.containsKey('musicResponsiveListItemRenderer')) {
              final result = _parseMusicItem(item['musicResponsiveListItemRenderer']);
              if (result != null) results.add(result);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SearchService: Music parse error: $e');
    }
    return results;
  }

  static SearchResult? _parseElementItem(dynamic element) {
    try {
      final newElement = element['newElement'];
      if (newElement == null) return null;
      final model = newElement['type']?['componentType']?['model'];
      if (model == null) return null;

      dynamic item;
      if (model.containsKey('musicListItemShelfModel')) {
        final items = model['musicListItemShelfModel']['data']?['items'];
        if (items != null && items is List && items.isNotEmpty) {
          item = items[0];
        }
      } else if (model.containsKey('musicListItemWrapperModel')) {
        item = model['musicListItemWrapperModel']['musicListItemData'];
      }

      if (item == null) return null;

      final title = item['title'] ?? '';
      if (title.toString().isEmpty) return null;

      final subtitle = item['subtitle'] ?? '';

      String? imageUrl;
      final sources = item['thumbnail']?['image']?['sources'];
      if (sources != null && sources is List && sources.isNotEmpty) {
        imageUrl = sources.last['url'];
      }

      String? videoId;
      String? browseId;
      String type = 'song';

      final onTap = item['onTap']?['innertubeCommand'];
      if (onTap != null) {
        if (onTap.containsKey('watchEndpoint')) {
          videoId = onTap['watchEndpoint']['videoId'];
          type = 'song';
        } else if (onTap.containsKey('browseEndpoint')) {
          browseId = onTap['browseEndpoint']['browseId'];
          if (browseId != null) {
            if (browseId.startsWith('MPREb')) type = 'album';
            else if (browseId.startsWith('UC')) type = 'artist';
            else if (browseId.startsWith('VL')) type = 'playlist';
          }
        }
      }

      return SearchResult(
        id: videoId ?? browseId ?? title.hashCode.toString(),
        title: title.toString(),
        subtitle: subtitle.toString(),
        type: type,
        imageUrl: imageUrl,
        videoId: videoId,
        browseId: browseId,
      );
    } catch (e) {
      return null;
    }
  }

  static SearchResult? _parseMusicItem(dynamic renderer) {
    try {
      final flexColumns = renderer['flexColumns'] ?? [];
      if (flexColumns.isEmpty) return null;

      final titleRun = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs']?[0];
      final title = titleRun?['text'] ?? '';

      String subtitle = '';
      if (flexColumns.length > 1) {
        final subtitleRuns = flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'] ?? [];
        subtitle = subtitleRuns.map((r) => r['text']).join();
      }

      String? imageUrl;
      final thumbnail = renderer['thumbnail']['musicThumbnailRenderer']['thumbnail']['thumbnails'];
      if (thumbnail != null && thumbnail.isNotEmpty) {
        imageUrl = thumbnail.last['url'];
      }

      final musicPlayButton = renderer['overlay']?['musicItemThumbnailOverlayRenderer']?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint'];
      String? videoId;
      String? browseId;
      String type = 'song';

      if (musicPlayButton != null) {
        final watchEndpoint = musicPlayButton['watchEndpoint'];
        if (watchEndpoint != null) {
          videoId = watchEndpoint['videoId'];
        }
      }

      final navigationEndpoint = renderer['flexColumns'][0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs']?[0]['navigationEndpoint'];
      if (navigationEndpoint != null) {
        if (navigationEndpoint.containsKey('watchEndpoint')) {
          videoId = navigationEndpoint['watchEndpoint']['videoId'];
          type = 'song';
        } else if (navigationEndpoint.containsKey('browseEndpoint')) {
          browseId = navigationEndpoint['browseEndpoint']['browseId'];
          if (browseId != null) {
            if (browseId.startsWith('MPREb')) type = 'album';
            else if (browseId.startsWith('UC')) type = 'artist';
            else if (browseId.startsWith('VL')) type = 'playlist';
          }
        }
      }

      if (title.isEmpty) return null;

      return SearchResult(
        id: videoId ?? browseId ?? title.hashCode.toString(),
        title: title,
        subtitle: subtitle,
        type: type,
        imageUrl: imageUrl,
        videoId: videoId,
        browseId: browseId,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<List<SearchResult>> browseAlbumOrPlaylist(String browseId, {int limit = 100}) async {
    try {
      String effectiveBrowseId = browseId;
      if (browseId.startsWith('PL')) {
        effectiveBrowseId = 'VL$browseId';
      }
      final payload = {
        'context': {
          'client': {
            'clientName': 'WEB',
            'clientVersion': '2.20241022.01.00',
            'hl': 'en',
            'gl': 'US',
          },
        },
        'browseId': effectiveBrowseId,
      };
      final response = await http.post(
        Uri.parse('$_ytUrl/browse?key=$_ytApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseBrowseResults(data, limit);
      }
    } catch (e) {
      debugPrint('SearchService: browseAlbumOrPlaylist error: $e');
    }
    return [];
  }

  static List<SearchResult> _parseBrowseResults(dynamic data, int limit) {
    final List<SearchResult> results = [];
    try {
      final contents = data['contents']['twoColumnBrowseResultsRenderer']['tabs']?[0]
          ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents == null) return results;

      for (var section in contents) {
        if (results.length >= limit) break;

        final items = section['musicShelfRenderer']?['contents'] ??
            section['musicPlaylistShelfRenderer']?['contents'];

        if (items != null) {
          for (var item in items) {
            if (results.length >= limit) break;
            if (item.containsKey('musicResponsiveListItemRenderer')) {
              final result = _parseMusicItem(item['musicResponsiveListItemRenderer']);
              if (result != null) results.add(result);
            }
          }
          continue;
        }

        final sectionItems = section['itemSectionRenderer']?['contents'];
        if (sectionItems != null) {
          for (var item in sectionItems) {
            if (results.length >= limit) break;
            if (item.containsKey('lockupViewModel')) {
              final lvm = item['lockupViewModel'];
              final contentId = lvm['contentId'] ?? '';
              final contentType = lvm['contentType'] ?? '';
              final meta = lvm['metadata']?['lockupMetadataViewModel'];
              final title = meta?['title']?['content'] ?? '';
              if (title.isEmpty || contentId.isEmpty) continue;

              String subtitle = '';
              try {
                final metaMeta = meta?['metadata']?['contentMetadataViewModel'];
                final rows = metaMeta?['metadataRows'];
                if (rows != null && rows is List) {
                  final parts = <String>[];
                  for (final row in rows) {
                    if (row is Map && row.containsKey('metadataParts')) {
                      final mp = row['metadataParts'];
                      if (mp != null && mp is List) {
                        for (final part in mp) {
                          if (part is Map && part['text'] != null) {
                            final t = part['text']['content'] ?? part['text'] ?? '';
                            if (t.toString().isNotEmpty) parts.add(t.toString());
                          }
                        }
                      }
                    }
                  }
                  subtitle = parts.join(' ');
                }
              } catch (_) {}

              String? imageUrl;
              try {
                final ci = lvm['contentImage'];
                final sources = ci?['collectionThumbnailViewModel']?['primaryThumbnail']?['thumbnailViewModel']?['image']?['sources'];
                if (sources is List && sources.isNotEmpty) {
                  imageUrl = sources[0]['url'];
                } else if (sources is String && sources.trim().isNotEmpty) {
                  imageUrl = sources;
                }
              } catch (_) {}

              if (contentType == 'LOCKUP_CONTENT_TYPE_VIDEO') {
                results.add(SearchResult(
                  id: contentId,
                  title: title,
                  subtitle: subtitle,
                  type: 'song',
                  imageUrl: imageUrl,
                  videoId: contentId,
                ));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('SearchService: _parseBrowseResults error: $e');
    }
    return results;
  }

  static Future<List<SearchSuggestion>> getSuggestions(String query) async {
    if (query.length < 2) return [];
    try {
      final payload = {
        ..._getMusicContext(),
        'input': query,
      };

      final response = await http.post(
        Uri.parse('$_ytMusicUrl/music/get_search_suggestions?prettyPrint=false'),
        headers: _getMusicHeaders(),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contents = data['contents'][0]['searchSuggestionsSectionRenderer']['contents'] ?? [];
        final results = contents
            .map((item) => SearchSuggestion(query: item['searchSuggestionRenderer']?['navigationEndpoint']?['searchEndpoint']?['query'] ?? ''))
            .where((s) => s.query.isNotEmpty)
            .toList();
        if (results.isNotEmpty) return results;
      }
    } catch (e) {
      debugPrint('SearchService: getSuggestions error: $e');
    }

    try {
      final payload = {
        ..._getWebContext(),
        'input': query,
      };
      final response = await http.post(
        Uri.parse('$_ytUrl/music/get_search_suggestions?key=$_ytApiKey&prettyPrint=false'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final section = data['contents']?[0]?['searchSuggestionsSectionRenderer']?['contents'] ?? [];
        return section
            .map((item) => SearchSuggestion(query: item['searchSuggestionRenderer']?['navigationEndpoint']?['searchEndpoint']?['query'] ?? item['searchSuggestionRenderer']?['query'] ?? ''))
            .where((s) => s.query.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('SearchService: getSuggestions web fallback error: $e');
    }
    return [];
  }
}
