import 'package:hive_flutter/hive_flutter.dart';

class PremiumService {
  static const _boxName = 'settings';
  static const _key = 'isPremium';

  static bool _cached = false;

  static bool get isPremium => _cached;

  static void load() {
    final box = Hive.box(_boxName);
    _cached = box.get(_key, defaultValue: false) as bool;
  }

  static Future<void> activate() async {
    final box = Hive.box(_boxName);
    await box.put(_key, true);
    _cached = true;
  }

  static Future<void> deactivate() async {
    final box = Hive.box(_boxName);
    await box.put(_key, false);
    _cached = false;
  }

  static Future<void> toggle() async {
    if (_cached) {
      await deactivate();
    } else {
      await activate();
    }
  }
}
