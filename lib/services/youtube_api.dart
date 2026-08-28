library;

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service YouTube pour les sous-catégories Gospel.
class YoutubeApiService {
  static const String _key = String.fromEnvironment('YOUTUBE_API_KEY');

  /// Recherche YouTube par terme.
  Future<List<dynamic>> search({
    required String query,
    int maxResults = 10,
  }) async {
    final uri = Uri.parse(
      'https://www.googleapis.com/youtube/v3/search?'
      'part=snippet'
      '&type=video'
      '&q=$query'
      '&maxResults=$maxResults'
      '&key=$_key',
    );

    final res = await http.get(uri);

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    return (data['items'] as List<dynamic>?)
        ?.map((item) => {
              'id': item['id']['videoId'] as String?,
              'title': item['snippet']['title'] as String?,
              'channel': item['snippet']['channelTitle'] as String?,
              'thumbnail': item['snippet']['thumbnails']['default']['url'] as String?,
              'url': 'https://www.youtube.com/watch?v=${item['id']['videoId']}',
            })
        .toList() ?? [];
  }

  /// Recherche par sous-catégorie Gospel.
  Future<List<dynamic>> searchBySub(String sub) async {
    return search(query: sub, maxResults: 10);
  }
}
