import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

const _timeout = Duration(seconds: 10);
const _wikiBase = 'https://fr.wikipedia.org/w/api.php';
const _userHeaders = {'User-Agent': 'MuzoApp/1.0 (music player; album descriptions)'};

/// Fetches a short album description from the Wikipedia API, Hivefy-style.
/// Returns an empty string when nothing is available so callers can hide it.
final albumDescriptionProvider = FutureProvider.family<String, (String, String)>(
  (ref, args) async {
    final (title, artist) = args;
    if (title.isEmpty) return '';

    try {
      // Search the French Wikipedia for the album page.
      final searchUri = Uri.parse(_wikiBase).replace(queryParameters: {
        'action': 'query',
        'list': 'search',
        'srsearch': '$title album $artist'.trim(),
        'srlimit': '5',
        'format': 'json',
      });
      final searchResp = await http
          .get(searchUri, headers: _userHeaders)
          .timeout(_timeout);
      if (searchResp.statusCode != 200) return '';

      final searchData = jsonDecode(searchResp.body) as Map<String, dynamic>;
      final results = (((searchData['query'] as Map?)?['search'] as List?) ?? [])
          .cast<Map<String, dynamic>>();
      if (results.isEmpty) return '';

      // Prefer a page whose title contains the album title (e.g. "Destin (album)")
      // over the artist's biography page.
      final loweredTitle = title.toLowerCase();
      String pageTitle = results.first['title']?.toString() ?? '';
      for (final r in results) {
        final t = r['title']?.toString() ?? '';
        if (t.toLowerCase().contains(loweredTitle)) {
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