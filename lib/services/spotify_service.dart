import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

class SpotifyCategory {
  final String id;
  final String name;
  final String? iconUrl;

  const SpotifyCategory({required this.id, required this.name, this.iconUrl});
}

class SpotifyService {
  static const _clientId = '454f2a3d05e44052b2f6cbf0dee15765';
  static const _clientSecret = 'b2a2ae2a96f94e928171dc525aa07a4c';
  static const _tokenUrl = 'https://accounts.spotify.com/api/token';
  static const _categoriesUrl = 'https://api.spotify.com/v1/browse/categories';

  static String? _accessToken;
  static DateTime? _tokenExpiry;

  static Future<String> _getAccessToken() async {
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
        'client_id': _clientId,
        'client_secret': _clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      final expiresIn = data['expires_in'] as int;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
      return _accessToken!;
    } else {
      throw Exception('Failed to get Spotify access token: ${response.statusCode}');
    }
  }

  static Future<List<SpotifyCategory>> getCategories({String locale = 'fr', int limit = 50}) async {
    final token = await _getAccessToken();
    final response = await http.get(
      Uri.parse('$_categoriesUrl?locale=$locale&limit=$limit'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final items = data['categories']['items'] as List;
      return items.map((item) {
        final icons = item['icons'] as List?;
        final iconUrl = icons != null && icons.isNotEmpty ? icons[0]['url'] as String? : null;
        return SpotifyCategory(
          id: item['id'] as String,
          name: item['name'] as String,
          iconUrl: iconUrl,
        );
      }).toList();
    } else {
      throw Exception('Failed to fetch categories: ${response.statusCode}');
    }
  }

  static void preloadImages(BuildContext context, List<SpotifyCategory> categories) {
    for (final cat in categories) {
      if (cat.iconUrl != null) {
        precacheImage(CachedNetworkImageProvider(cat.iconUrl!), context).catchError((_) {});
      }
    }
  }
}
