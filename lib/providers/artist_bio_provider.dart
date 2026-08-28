import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const _timeout = Duration(seconds: 12);
const _wikiBase = 'https://fr.wikipedia.org/w/api.php';
const _userHeaders = {
  'User-Agent': 'MuzoApp/1.0 (music player; artist biographies)'
};

/// Fetches a short artist biography from the French Wikipedia,
/// Hivefy-style. Returns an empty string when nothing is available so
/// callers can hide it or fall back to the plain name.
final artistBioProvider = FutureProvider.family<String, String>(
  (ref, artistName) async {
    final name = artistName.trim();
    if (name.isEmpty) return '';

    try {
      // Search the French Wikipedia for the artist page.
      final searchUri = Uri.parse(_wikiBase).replace(queryParameters: {
        'action': 'query',
        'list': 'search',
        'srsearch': name,
        'srlimit': '5',
        'format': 'json',
      });
      final searchResp = await http
          .get(searchUri, headers: _userHeaders)
          .timeout(_timeout);
      if (searchResp.statusCode != 200) return '';

      final searchData = jsonDecode(searchResp.body) as Map<String, dynamic>;
      final results = (((searchData['query'] as Map?)?['search'] as List?) ??
              [])
          .cast<Map<String, dynamic>>();
      if (results.isEmpty) return '';

      // Prefer a page whose title looks like the artist name itself.
      final lowered = name.toLowerCase();
      String pageTitle = results.first['title']?.toString() ?? '';
      for (final r in results) {
        final t = r['title']?.toString() ?? '';
        if (t.toLowerCase().contains(lowered)) {
          pageTitle = t;
          break;
        }
      }
      if (pageTitle.isEmpty) return '';

      final extractUri = Uri.parse(_wikiBase).replace(queryParameters: {
        'action': 'query',
        'prop': 'extracts',
        'exintro': '1',
        'explaintext': '1',
        'format': 'json',
        'titles': pageTitle,
      });
      final extractResp = await http
          .get(extractUri, headers: _userHeaders)
          .timeout(_timeout);
      if (extractResp.statusCode != 200) return '';

      final extractData = jsonDecode(extractResp.body) as Map<String, dynamic>;
      final pages = ((extractData['query'] as Map?)?['pages'] as Map?) ?? {};
      for (final page in pages.values) {
        if (page is Map<String, dynamic>) {
          final extract = page['extract']?.toString() ?? '';
          if (extract.isNotEmpty) return extract.trim();
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  },
);