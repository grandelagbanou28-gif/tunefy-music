import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/services/content_cache_service.dart';

/// One current chart entry from an Apple storefront.
@immutable
class TrendSong {
  final String title;
  final String artist;
  final String genre; // iTunes genre label, e.g. "Hip-Hop/Rap"
  final String art;

  const TrendSong({
    required this.title,
    required this.artist,
    required this.genre,
    required this.art,
  });

  Map<String, dynamic> toJson() => {'t': title, 'a': artist, 'g': genre, 'c': art};

  static TrendSong fromJson(Map<String, dynamic> j) => TrendSong(
        title: j['t'] as String? ?? '',
        artist: j['a'] as String? ?? '',
        genre: j['g'] as String? ?? '',
        art: j['c'] as String? ?? '',
      );
}

/// One editorial album from an Apple storefront (RSS top albums).
@immutable
class RssAlbum {
  final String title;
  final String artist;
  final String cover;

  const RssAlbum({
    required this.title,
    required this.artist,
    required this.cover,
  });

  Map<String, dynamic> toJson() => {'t': title, 'a': artist, 'c': cover};

  static RssAlbum fromJson(Map<String, dynamic> j) => RssAlbum(
        title: j['t'] as String? ?? '',
        artist: j['a'] as String? ?? '',
        cover: j['c'] as String? ?? '',
      );
}

/// One editorial playlist from an Apple storefront (RSS top playlists).
@immutable
class RssPlaylist {
  final String title;
  final String author;
  final String cover;

  const RssPlaylist({
    required this.title,
    required this.author,
    required this.cover,
  });

  Map<String, dynamic> toJson() => {'t': title, 'a': author, 'c': cover};

  static RssPlaylist fromJson(Map<String, dynamic> j) => RssPlaylist(
        title: j['t'] as String? ?? '',
        author: j['a'] as String? ?? '',
        cover: j['c'] as String? ?? '',
      );
}

/// Modern-artist source: Apple's public iTunes RSS song charts.
///
/// `https://itunes.apple.com/<store>/rss/topsongs/limit=50/json` returns the
/// REAL current top songs of any storefront (fr, us, ng, ci, za...) — no key,
/// no quota. This is what powers:
///  • the Charts / Trending categories (true daily tops), and
///  • the "modern boost" that injects a couple of current chart-matching
///    tracks into every music sub-category so pages never feel dated.
///
/// Charts are cached on disk for 48h — identical refresh cadence as the
/// sub-section cache, so everything renews together every 2 days.
class TrendingService {
  TrendingService._();

  static const _timeout = Duration(seconds: 10);

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    'Accept': '*/*',
  };

  // ─── Fetch ────────────────────────────────────────────────────────────────

  /// Current top songs of one storefront (48h disk cache).
  static Future<List<TrendSong>> topSongs(String countryCode) async {
    final cc = countryCode.toLowerCase();
    final key = 'trends|$cc';
    try {
      final cached = await ContentCacheService.instance.readJsonIfFresh(key);
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => TrendSong.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    try {
      final uri =
          Uri.parse('https://itunes.apple.com/$cc/rss/topsongs/limit=50/json');
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final feed = (body['feed'] as Map?) ?? const {};
      final entries = (feed['entry'] as List?) ?? const [];
      final songs = <TrendSong>[];
      for (final e in entries) {
        try {
          final m = Map<String, dynamic>.from(e as Map);
          final name =
              (((m['im:name'] as Map?) ?? const {})['label'] as String?) ?? '';
          final artist =
              (((m['im:artist'] as Map?) ?? const {})['label'] as String?) ??
                  '';
          if (name.isEmpty || artist.isEmpty) continue;
          final genre =
              ((((m['category'] as Map?) ?? const {})['attributes'] as Map?) ??
                      const {})['label'] as String? ??
                  '';
          var art = '';
          final images = (m['im:image'] as List?) ?? const [];
          if (images.isNotEmpty) {
            art = ((images.last as Map)['label'] as String?) ?? '';
            art = art.replaceFirst(RegExp(r'/\d+x\d+BB'), '/600x600BB');
          }
          songs.add(TrendSong(
              title: name, artist: artist, genre: genre, art: art));
        } catch (_) {}
      }
      if (songs.isNotEmpty) {
        await ContentCacheService.instance
            .writeJson(key, songs.map((s) => s.toJson()).toList());
      }
      return songs;
    } catch (e) {
      debugPrint('TRENDS $cc fail :: $e');
      return const [];
    }
  }

  // ─── Sub-category → storefront mapping ───────────────────────────────────

  /// Current top albums of one storefront (48h disk cache).
  static Future<List<RssAlbum>> topAlbums(String countryCode) async {
    final cc = countryCode.toLowerCase();
    final key = 'trendalb|$cc';
    try {
      final cached = await ContentCacheService.instance.readJsonIfFresh(key);
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => RssAlbum.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    try {
      final uri =
          Uri.parse('https://itunes.apple.com/$cc/rss/topalbums/limit=25/json');
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final feed = (body['feed'] as Map?) ?? const {};
      final entries = (feed['entry'] as List?) ?? const [];
      final albums = <RssAlbum>[];
      for (final e in entries) {
        try {
          final m = Map<String, dynamic>.from(e as Map);
          final name =
              (((m['im:name'] as Map?) ?? const {})['label'] as String?) ?? '';
          final artist =
              (((m['im:artist'] as Map?) ?? const {})['label'] as String?) ??
                  '';
          if (name.isEmpty || artist.isEmpty) continue;
          var art = '';
          final images = (m['im:image'] as List?) ?? const [];
          if (images.isNotEmpty) {
            art = ((images.last as Map)['label'] as String?) ?? '';
            art = art.replaceFirst(RegExp(r'/\d+x\d+BB'), '/600x600BB');
          }
          albums.add(RssAlbum(title: name, artist: artist, cover: art));
        } catch (_) {}
      }
      if (albums.isNotEmpty) {
        await ContentCacheService.instance
            .writeJson(key, albums.map((a) => a.toJson()).toList());
      }
      return albums;
    } catch (e) {
      debugPrint('TRENDALB $cc fail :: $e');
      return const [];
    }
  }

  /// Current top playlists of one storefront (48h disk cache).
  static Future<List<RssPlaylist>> topPlaylists(String countryCode) async {
    final cc = countryCode.toLowerCase();
    final key = 'trendpl|$cc';
    try {
      final cached = await ContentCacheService.instance.readJsonIfFresh(key);
      if (cached != null && cached.isNotEmpty) {
        return cached
            .map((e) => RssPlaylist.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (_) {}

    try {
      final uri = Uri.parse(
          'https://itunes.apple.com/$cc/rss/topplaylists/limit=25/json');
      final resp = await http.get(uri, headers: _headers).timeout(_timeout);
      if (resp.statusCode != 200) return const [];
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final feed = (body['feed'] as Map?) ?? const {};
      final entries = (feed['entry'] as List?) ?? const [];
      final playlists = <RssPlaylist>[];
      for (final e in entries) {
        try {
          final m = Map<String, dynamic>.from(e as Map);
          final name =
              (((m['im:name'] as Map?) ?? const {})['label'] as String?) ?? '';
          final author =
              (((m['im:artist'] as Map?) ?? const {})['label'] as String?) ??
                  '';
          if (name.isEmpty) continue;
          var art = '';
          final images = (m['im:image'] as List?) ?? const [];
          if (images.isNotEmpty) {
            art = ((images.last as Map)['label'] as String?) ?? '';
            art = art.replaceFirst(RegExp(r'/\d+x\d+BB'), '/600x600BB');
          }
          playlists.add(
              RssPlaylist(title: name, author: author, cover: art));
        } catch (_) {}
      }
      if (playlists.isNotEmpty) {
        await ContentCacheService.instance
            .writeJson(key, playlists.map((p) => p.toJson()).toList());
      }
      return playlists;
    } catch (e) {
      debugPrint('TRENDPL $cc fail :: $e');
      return const [];
    }
  }

  // ─── Sub-category → storefront mapping ───────────────────────────────────

  /// Maps a Charts/Trending sub name to the Apple storefront(s) it should
  /// mirror. Unknown/global subs blend FR + US. More specific keys come
  /// first because matching is substring-based.
  static List<String> countriesForSub(String sub) {
    final s = _norm(sub);
    const map = <String, List<String>>{
      'south africa': ['za'],
      'naija': ['ng'],
      'afro bangers': ['ng', 'ci', 'gh'],
      'viral now': ['gb', 'us'],
      'fr du jour': ['fr'],
      'rising france': ['fr'],
      'top us': ['us'],
      'france': ['fr'],
      'usa': ['us'],
      'uk': ['gb'],
      'nigeria': ['ng'],
      'ghana': ['gh'],
      "cote d ivoire": ['ci'],
      'benin': ['bj'],
      'africa': ['ng', 'za'],
    };
    for (final k in map.keys) {
      if (s.contains(k)) return map[k]!;
    }
    return ['fr', 'us'];
  }

  // ─── Genre-matched picks ("modern boost") ────────────────────────────────

  /// Our category keys → iTunes chart genre labels. Categories absent here
  /// simply receive no injection.
  static const Map<String, List<String>> _genreByCategory = {
    'hip-hop': ['Hip-Hop/Rap'],
    'rap': ['Hip-Hop/Rap'],
    'rap francais': ['Hip-Hop/Rap'],
    'pop': ['Pop', 'K-Pop'],
    'k-pop': ['K-Pop', 'Pop'],
    'r&b': ['R&B/Soul'],
    'soul': ['R&B/Soul'],
    'rock': ['Rock', 'Alternative'],
    'indie': ['Alternative', 'Indie'],
    'latin': ['Latin'],
    'country': ['Country'],
    'reggae': ['Reggae'],
    'electronic': ['Dance', 'Electronic'],
    'house': ['Dance', 'Electronic'],
    'metal': ['Metal', 'Rock'],
    'blues': ['Blues'],
    'jazz': ['Jazz'],
    'classical': ['Classical'],
    'gospel': ['Christian', 'Gospel'],
    'afrobeats': ['Afrobeats'],
    'afro hits': ['Afrobeats'],
    'amapiano': ['Afrobeats', 'Dance'],
    'dancehall': ['Reggae'],
    'rumba congolaise': ['Afrobeats', 'Worldwide'],
    'musique arabe': ['Worldwide'],
    'bande originale': ['Soundtrack'],
    'drill': ['Hip-Hop/Rap'],
    'chanson francaise': ['French Pop'],
    'folk & acoustic': ['Singer/Songwriter', 'Alternative'],
    'funk': ['R&B/Soul', 'Funk'],
    'romance': ['Pop', 'R&B/Soul'],
  };

  /// Up to [n] current-chart tracks whose iTunes genre matches [category].
  /// Rotation is driven by the shared 2-day bucket so picks change at every
  /// content refresh.
  static Future<List<TrendSong>> picksForCategory(
    String category,
    int bucket,
    int n,
  ) async {
    final labels = _genreByCategory[category.trim().toLowerCase()];
    if (labels == null || labels.isEmpty || n <= 0) return const [];
    final pools =
        await Future.wait([topSongs('us'), topSongs('fr'), topSongs('gb')]);
    final seen = <String>{};
    final matches = <TrendSong>[];
    for (final pool in pools) {
      for (final t in pool) {
        if (!labels.contains(t.genre)) continue;
        final key = '${t.title}|${t.artist}'.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        matches.add(t);
      }
    }
    if (matches.isEmpty) return const [];
    return ContentCacheService.rotate(matches, bucket * 3).take(n).toList();
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r"[’'`-]"), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
