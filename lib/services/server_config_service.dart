import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerConfigService {
  static const String _boxName = 'settings';
  static const String _serverKey = 'custom_server_url';
  static const String _serverEnabledKey = 'custom_server_enabled';
  static const String defaultServerUrl = 'http://192.168.1.104:42299';
  static const String muzoBackendUrl = 'http://192.168.1.102:8000';

  static Box get _box => Hive.box(_boxName);

  static String get serverUrl => _box.get(_serverKey, defaultValue: defaultServerUrl);
  static bool get isEnabled => _box.get(_serverEnabledKey, defaultValue: false);

  static Future<void> setServerUrl(String url) async {
    await _box.put(_serverKey, url);
  }

  static Future<void> setEnabled(bool enabled) async {
    await _box.put(_serverEnabledKey, enabled);
  }

  static Future<String?> getStreamUrl(String videoId) async {
    if (!isEnabled) return null;
    try {
      final uri = Uri.parse('$serverUrl/latest_version?id=$videoId&itag=140');
      return uri.toString();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getSearchUrl(String query) async {
    if (!isEnabled) return null;
    try {
      final uri = Uri.parse('$serverUrl/api/v1/search?q=$query&type=video');
      return uri.toString();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getSaavnStreamUrlLocal(String title, String artist) async {
    try {
      final uri = Uri.parse('$muzoBackendUrl/api/jiosaavn/search')
          .replace(queryParameters: {'title': title, 'artist': artist});
        final response = await http.get(uri).timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final downloadUrl = data['downloadUrl'] as String?;
        if (downloadUrl != null && downloadUrl.isNotEmpty) {
          return downloadUrl;
        }
      }
    } catch (e) {
      // Local server unavailable, fall through
    }
    return null;
  }
}
