import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tunefy/data/model/podcast_models.dart';

class PodcastSearchService {
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String _apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'User-Agent': 'com.google.android.apps.youtube.music/7.27.52 (Linux; U; Android 14; en_US; sdk_gphone64_x86_64 Build/UE1A.230829.036.A1) gzip',
      'X-Goog-Api-Key': _apiKey,
    };
  }

  static Map<String, dynamic> _getContext() {
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

  static Future<List<PodcastChannel>> searchPodcasts(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = {
        'query': query,
        'params': 'EgWKAQIIAWoMEAoQDhABGAE%3D',
      };

      final payload = {
        ..._getContext(),
        ...params,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/search?prettyPrint=false'),
        headers: _getHeaders(),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parsePodcastChannels(data, limit);
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  static Future<List<PodcastEpisode>> searchEpisodes(String query, {int limit = 30}) async {
    if (query.trim().isEmpty) return [];

    try {
      final params = {
        'query': query,
        'params': 'EgWKAQIIAWoKEAMQBBAJEAoQBQ%3D%3D',
      };

      final payload = {
        ..._getContext(),
        ...params,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/search?prettyPrint=false'),
        headers: _getHeaders(),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parsePodcastEpisodes(data, limit);
      }
    } catch (e) {
      return [];
    }
    return [];
  }

  static List<PodcastChannel> _parsePodcastChannels(dynamic data, int limit) {
    final List<PodcastChannel> results = [];
    try {
      final contents = data['contents']['tabbedSearchResultsRenderer']['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents'];
      for (var section in contents) {
        if (section.containsKey('musicShelfRenderer')) {
          final items = section['musicShelfRenderer']['contents'] ?? [];
          for (var item in items) {
            if (item.containsKey('musicResponsiveListItemRenderer')) {
              final renderer = item['musicResponsiveListItemRenderer'];
              final channel = _parseChannelItem(renderer);
              if (channel != null) {
                results.add(channel);
                if (results.length >= limit) break;
              }
            }
          }
        }
        if (section.containsKey('musicCarouselShelfRenderer')) {
          final items = section['musicCarouselShelfRenderer']['contents'] ?? [];
          for (var item in items) {
            if (item.containsKey('musicResponsiveListItemRenderer')) {
              final renderer = item['musicResponsiveListItemRenderer'];
              final channel = _parseChannelItem(renderer);
              if (channel != null) {
                results.add(channel);
                if (results.length >= limit) break;
              }
            }
          }
        }
        if (results.length >= limit) break;
      }
    } catch (e) {
      // Parsing fallback
    }
    return results;
  }

  static PodcastChannel? _parseChannelItem(dynamic renderer) {
    try {
      final flexColumns = renderer['flexColumns'] ?? [];
      if (flexColumns.isEmpty) return null;

      final titleRun = flexColumns[0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs']?[0];
      final title = titleRun?['text'] ?? '';

      String description = '';
      if (flexColumns.length > 1) {
        final subtitleRuns = flexColumns[1]['musicResponsiveListItemFlexColumnRenderer']['text']['runs'] ?? [];
        description = subtitleRuns.map((r) => r['text']).join();
      }

      String? imageUrl;
      final thumbnail = renderer['thumbnail']['musicThumbnailRenderer']['thumbnail']['thumbnails'];
      if (thumbnail != null && thumbnail.isNotEmpty) {
        imageUrl = thumbnail.last['url'];
      }

      String? browseId;
      final navigationEndpoint = renderer['flexColumns'][0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs']?[0]['navigationEndpoint'];
      if (navigationEndpoint != null && navigationEndpoint.containsKey('browseEndpoint')) {
        browseId = navigationEndpoint['browseEndpoint']['browseId'];
      }

      if (title.isEmpty) return null;

      return PodcastChannel(
        id: browseId ?? title.hashCode.toString(),
        title: title,
        description: description,
        imageUrl: imageUrl,
      );
    } catch (e) {
      return null;
    }
  }

  static List<PodcastEpisode> _parsePodcastEpisodes(dynamic data, int limit) {
    final List<PodcastEpisode> results = [];
    try {
      final contents = data['contents']['tabbedSearchResultsRenderer']['tabs'][0]['tabRenderer']['content']['sectionListRenderer']['contents'];
      for (var section in contents) {
        if (section.containsKey('musicShelfRenderer')) {
          final items = section['musicShelfRenderer']['contents'] ?? [];
          for (var item in items) {
            if (item.containsKey('musicResponsiveListItemRenderer')) {
              final renderer = item['musicResponsiveListItemRenderer'];
              final episode = _parseEpisodeItem(renderer);
              if (episode != null) {
                results.add(episode);
                if (results.length >= limit) break;
              }
            }
          }
        }
        if (results.length >= limit) break;
      }
    } catch (e) {
      // Parsing fallback
    }
    return results;
  }

  static PodcastEpisode? _parseEpisodeItem(dynamic renderer) {
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

      String? videoId;
      final musicPlayButton = renderer['overlay']['musicItemThumbnailOverlayRenderer']['content']['musicPlayButtonRenderer']['playNavigationEndpoint'];
      if (musicPlayButton != null) {
        final watchEndpoint = musicPlayButton['watchEndpoint'];
        if (watchEndpoint != null) {
          videoId = watchEndpoint['videoId'];
        }
      }

      final navigationEndpoint = renderer['flexColumns'][0]['musicResponsiveListItemFlexColumnRenderer']['text']['runs']?[0]['navigationEndpoint'];
      if (navigationEndpoint != null && navigationEndpoint.containsKey('watchEndpoint')) {
        videoId = navigationEndpoint['watchEndpoint']['videoId'];
      }

      if (title.isEmpty) return null;

      return PodcastEpisode(
        id: videoId ?? title.hashCode.toString(),
        title: title,
        channelTitle: subtitle,
        imageUrl: imageUrl,
        videoId: videoId,
      );
    } catch (e) {
      return null;
    }
  }

  static Future<List<PodcastEpisode>> getPopularPodcasts({int limit = 30}) async {
    return searchEpisodes('popular podcast', limit: limit);
  }

  static Future<List<PodcastChannel>> getTopPodcastChannels({int limit = 20}) async {
    return searchPodcasts('top podcasts', limit: limit);
  }
}
