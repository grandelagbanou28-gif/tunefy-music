import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:muzo/models/muzo_item.dart';
import 'package:muzo/models/user_data.dart';

/// Extreme-light Supabase client (REST + GoTrue) used as the durable DB layer.
///
/// Identity is a per-device *anonymous* Supabase user (kept alive via its
/// refresh token stored in Hive). Every table is scoped by RLS to `auth.uid()`,
/// so an anonymous user can only read/write their own rows. All operations are
/// wrapped by the caller in try/catch — if Supabase is unreachable the app
/// keeps working purely local (Hive) with no data loss.
class SupabaseStore {
  static const String url = 'https://lvwwbuujvknzmstzmjam.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2d3didXVqdmtuem1zdHptamFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc5Mzg3NTUsImV4cCI6MjEwMzUxNDc1NX0.BsM8AaUi6GHAV6KsmS70ppFDFuyWa0Vl9mpveqyRyQA';

  static const String _secretKey = 'supabase_secret';
  static const int maxHistoryLength = 500;

  String? _accessToken;
  String? _uid;
  bool _ready = false;
  bool _signingIn = false;

  /// Unique anonymous user id for this device (empty until first sign-in).
  String get uid => _uid ?? '';
  bool get ready => _ready;

  /// Sign in anonymously. On failure (offline / API down) the app stays offline
  /// and keeps whatever uid we already know from a previous session.
  Future<void> init() async {
    if (_signingIn) return;
    _signingIn = true;
    try {
      final box = Hive.box('settings');
      final stored = box.get(_secretKey);
      if (stored is String && stored.isNotEmpty) {
        final map = _decode(stored);
        final refresh = map['refresh_token']?.toString();
        if (refresh != null && refresh.isNotEmpty) {
          final ok = await _refresh(refresh);
          if (ok) return;
        }
        // Refresh failed (revoked / offline): remember the uid so a re-login
        // re-attaches to the same profile as soon as the network returns.
        _uid = map['uid']?.toString();
      }
      await _signup();
    } catch (e) {
      debugPrint('Supabase init failed (degraded, local only): $e');
    } finally {
      _signingIn = false;
    }
  }

  Future<bool> _refresh(String refreshToken) async {
    try {
      final resp = await http.post(
        Uri.parse('url/auth/v1/token?grant_type=refresh_token'),
        headers: _headers(),
        body: jsonEncode({'refresh_token': refreshToken}),
      );
if (resp.statusCode != 200) return false;
          final data = _decode(resp.body);
          _accessToken = data['access_token']?.toString();
          _uid = data['user']?['id']?.toString() ?? _uid;
          _lastRefreshToken = data['refresh_token']?.toString() ?? refreshToken;
          _ready = _accessToken != null;
          if (_accessToken != null) _saveSecret();
          return _ready;
    } catch (e) {
      debugPrint('Supabase refresh failed: $e');
      return false;
    }
  }

  Future<void> _signup() async {
    final resp = await http.post(
      Uri.parse('url/auth/v1/signup'),
      headers: _headers(),
      body: '{}',
    );
    if (resp.statusCode != 200) {
      throw Exception('Supabase signup ${resp.statusCode}: ${resp.body}');
    }
    final data = _decode(resp.body);
    _accessToken = data['access_token']?.toString();
    _uid = data['user']?['id']?.toString();
    _lastRefreshToken = data['refresh_token']?.toString();
    if (_accessToken == null || _uid == null) {
      throw Exception('Supabase signup: missing token');
    }
    _ready = true;
    _saveSecret();
    await _upsertProfile();
  }

  void _saveSecret() {
    try {
      final box = Hive.box('settings');
      box.put(
        _secretKey,
        jsonEncode({
          'uid': _uid,
          'refresh_token': _lastRefreshToken ?? '',
        }),
      );
    } catch (e) {
      debugPrint('Could not persist Supabase secret: $e');
    }
  }

  String? _lastRefreshToken;

  Future<void> _upsertProfile() async {
    final uid = _uid;
    if (uid == null) return;
    await _post(
      'profiles',
      {'id': uid},
      onConflict: 'id',
    );
  }

  Map<String, String> _headers() => {
        'apikey': anonKey,
        'Authorization': 'Bearer ${_accessToken ?? anonKey}',
        'Content-Type': 'application/json',
      };

  /// Profile seeding once per anonymous session.
  bool _profileSeeded = false;
  Future<void> _ensureProfile() async {
    if (_profileSeeded || _uid == null || _accessToken == null) return;
    try {
      await _post(
        'profiles',
        {'id': _uid},
        onConflict: 'id',
      );
      _profileSeeded = true;
    } catch (_) {
      // Non-fatal: profile may not exist yet if the migration hasn't run.
    }
  }

  Uri _rest(String table, {String? onConflict, Map<String, String>? params}) {
    final q = <String, String>{'select': '*'};
    if (onConflict != null) q['on_conflict'] = onConflict;
    if (params != null) q.addAll(params);
    return Uri.parse('url/rest/v1/$table').replace(queryParameters: q);
  }

  Map<String, dynamic> _decode(String body) =>
      body.isEmpty ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(body));

  // ─────────────────────────────── History ────────────────────────────────

  Future<void> addToHistory(MuzoItem song, {String? at}) async {
    await _ensureProfile();
    await _post(
      'history',
      {'profile_id': _uid, 'video_id': song.videoId, 'song': song.toJson()},
      onConflict: 'profile_id,video_id',
    );
  }

  Future<void> removeFromHistory(String videoId) async {
    await _delete('history', {'video_id': 'eq.${_q(videoId)}'});
  }

  Future<void> clearHistory() async {
    await _delete('history');
  }

  Future<List<MuzoItem>> fetchHistory() async {
    final rows = await _get('history');
    final items = <MuzoItem>[];
    for (final row in rows) {
      try {
        items.add(MuzoItem.fromJson(row['song']));
      } catch (_) {}
    }
    return items;
  }

  // ─────────────────────────────── Favorites ──────────────────────────────

  Future<void> addToFavorites(MuzoItem song) async {
    await _ensureProfile();
    await _post(
      'liked_songs',
      {'profile_id': _uid, 'video_id': song.videoId, 'song': song.toJson()},
      onConflict: 'profile_id,video_id',
    );
  }

  Future<void> removeFromFavorites(String videoId) async {
    await _delete('liked_songs', {'video_id': 'eq.${_q(videoId)}'});
  }

  Future<List<MuzoItem>> fetchFavorites() async {
    final rows = await _get('liked_songs');
    final items = <MuzoItem>[];
    for (final row in rows) {
      try {
        items.add(MuzoItem.fromJson(row['song']));
      } catch (_) {}
    }
    return items;
  }

  // ──────────────────────────── Subscriptions ─────────────────────────────

  Future<void> addSubscription(Channel channel) async {
    await _ensureProfile();
    await _post(
      'subscriptions',
      {'profile_id': _uid, 'channel_id': channel.channelId ?? channel.name, 'data': channel.toJson()},
      onConflict: 'profile_id,channel_id',
    );
  }

  Future<void> removeSubscription(String browseId) async {
    await _delete('subscriptions', {'channel_id': 'eq.${_q(browseId)}'});
  }

  Future<List<Channel>> fetchSubscriptions() async {
    final rows = await _get('subscriptions');
    final items = <Channel>[];
    for (final row in rows) {
      try {
        items.add(Channel.fromJson(row['data']));
      } catch (_) {}
    }
    return items;
  }

  // ─────────────────────────────── Playlists ──────────────────────────────

  Future<void> savePlaylist(Playlist playlist) async {
    await _ensureProfile();
    await _post(
      'playlists',
      {'profile_id': _uid, 'name': playlist.name, 'data': playlist.toJson()},
      onConflict: 'profile_id,name',
    );
  }

  Future<void> deletePlaylist(String name) async {
    await _delete('playlists', {'name': 'eq.${_q(name)}'});
  }

  Future<List<Playlist>> fetchPlaylists() async {
    final rows = await _get('playlists');
    final items = <Playlist>[];
    for (final row in rows) {
      try {
        items.add(Playlist.fromJson(row['data']));
      } catch (_) {}
    }
    return items;
  }

  // ────────────────────────── Settings snapshot ───────────────────────────

  Future<void> saveSetting(String key, Map<String, dynamic> value) async {
    await _ensureProfile();
    await _post(
      'settings',
      {'profile_id': _uid, 'key': key, 'value': value},
      onConflict: 'profile_id,key',
    );
  }

  // ────────────────────────────── Low level ───────────────────────────────

  Future<List<Map<String, dynamic>>> _get(
      String table, {Map<String, String>? params}) async {
    final resp = await http.get(
      _rest(table, params: params ?? const {}),
      headers: _headers(),
    );
    if (resp.statusCode != 200) {
      throw Exception('GET $table ${resp.statusCode}: ${resp.body}');
    }
    if (resp.body.isEmpty) return [];
    final decoded = jsonDecode(resp.body) as List;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _post(
    String table,
    Map<String, dynamic> body, {
    String? onConflict,
  }) async {
    final resp = await http.post(
      _rest(table, onConflict: onConflict),
      headers: {..._headers(), 'Prefer': 'resolution=merge-duplicates,return=minimal'},
      body: jsonEncode(body),
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('POST $table ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<void> _delete(String table, [Map<String, String>? params]) async {
    final resp = await http.delete(
      _rest(table, params: params ?? const {}),
      headers: {..._headers(), 'Prefer': 'return=minimal'},
    );
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('DELETE $table ${resp.statusCode}: ${resp.body}');
    }
  }

  static String _q(String value) => Uri.encodeQueryComponent(value);
}