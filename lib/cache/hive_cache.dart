import 'package:hive/hive.dart';

class HiveCache {
  static Box? _cacheBox;

  static Future<void> init() async {
    _cacheBox = await Hive.openBox('cache');
  }

  static void set(String key, dynamic value) {
    _cacheBox?.put(key, value);
  }

  static dynamic get(String key) {
    return _cacheBox?.get(key);
  }

  static void remove(String key) {
    _cacheBox?.delete(key);
  }

  static bool contains(String key) {
    return _cacheBox?.containsKey(key) ?? false;
  }

  static void clearExpired(Duration maxAge) {
    if (_cacheBox == null) return;
    final now = DateTime.now();
    final keys = _cacheBox!.keys.toList();
    for (final key in keys) {
      final meta = _cacheBox!.get('${key}_meta');
      if (meta is Map && meta['cached_at'] != null) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(meta['cached_at'] as int);
        if (now.difference(cachedAt) > maxAge) {
          _cacheBox!.delete(key);
          _cacheBox!.delete('${key}_meta');
        }
      }
    }
  }

  static void storeWithMeta(String key, dynamic value) {
    set(key, value);
    set('${key}_meta', {'cached_at': DateTime.now().millisecondsSinceEpoch});
  }

  static Map<String, dynamic>? getWithMeta(String key) {
    final value = get(key);
    final meta = get('${key}_meta');
    if (value == null) return null;
    return {'value': value, 'meta': meta};
  }
}