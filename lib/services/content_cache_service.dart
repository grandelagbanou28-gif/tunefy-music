import 'dart:convert';

import 'package:muzo/models/muzo_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent content cache for category sub-sections.
///
/// Every resolved sub-section is stored on disk together with its save time.
/// A cached entry is served instantly while it is younger than [ttl] (72h),
/// so pages open immediately and every list naturally refreshes — with fresh
/// network data AND a new rotation order — once every 3 days.
class ContentCacheService {
  ContentCacheService._();

  static final ContentCacheService instance = ContentCacheService._();

  /// How long a cached sub-section stays valid: 3 days.
  static const Duration ttl = Duration(hours: 72);

  static const String _prefix = 'ccache.v1.';

  Future<Map<String, dynamic>?> _readRaw(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached songs for [key], or null when absent, expired or
  /// corrupt. Expired entries are left in place — they are overwritten by the
  /// next successful write.
  Future<List<MuzoItem>?> readIfFresh(String key) async {
    final raw = await _readRaw(key);
    if (raw == null) return null;
    try {
      final ts = (raw['ts'] as num?)?.toInt() ?? 0;
      final saved = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(saved) >= ttl) return null;
      final songs = (raw['songs'] as List? ?? [])
          .map((e) => MuzoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (songs.isEmpty) return null;
      return songs;
    } catch (_) {
      return null;
    }
  }

  /// Persists [songs] under [key]. Failures are silently ignored — the cache
  /// is a pure optimization.
  Future<void> write(String key, List<MuzoItem> songs) async {
    if (songs.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', jsonEncode({
        'ts': DateTime.now().millisecondsSinceEpoch,
        'songs': songs.map((s) => s.toJson()).toList(),
      }));
    } catch (_) {}
  }

  /// Generic JSON-list cache with the same TTL. Returns the stored list when
  /// fresh, otherwise null.
  Future<List<dynamic>?> readJsonIfFresh(String key) async {
    final raw = await _readRaw(key);
    if (raw == null) return null;
    try {
      final ts = (raw['ts'] as num?)?.toInt() ?? 0;
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) >=
          ttl) {
        return null;
      }
      return raw['data'] as List?;
    } catch (_) {
      return null;
    }
  }

  Future<void> writeJson(String key, List<dynamic> data) async {
    if (data.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_prefix$key', jsonEncode({
        'ts': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }));
    } catch (_) {}
  }

  /// Number of 3-day buckets since the epoch — the rotation counter that makes
  /// "every 3 days everything refreshes" deterministic across devices.
  static int get refreshBucket =>
      DateTime.now().toUtc().difference(DateTime.utc(2024, 1, 1)).inDays ~/ 3;

  /// Rotates a list by [offset] positions so each bucket leads with different
  /// content without discarding any item.
  static List<T> rotate<T>(List<T> items, int offset) {
    if (items.length <= 1 || offset <= 0) return items;
    final off = offset % items.length;
    return [...items.skip(off), ...items.take(off)];
  }
}
