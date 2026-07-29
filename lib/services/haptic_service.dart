import 'package:flutter/services.dart';

enum HapticType { light, medium, heavy, selection, success, warning, error }

class HapticService {
  HapticService._();

  static final HapticService instance = HapticService._();
  factory HapticService() => instance;

  static bool _enabled = true;

  static void setEnabled(bool value) => _enabled = value;
  static bool get isEnabled => _enabled;

  void light() => _feedback(HapticType.light);
  void medium() => _feedback(HapticType.medium);
  void heavy() => _feedback(HapticType.heavy);
  void selection() => _feedback(HapticType.selection);
  void success() => _feedback(HapticType.success);
  void warning() => _feedback(HapticType.warning);
  void error() => _feedback(HapticType.error);

  static void tap() => instance.light();
  static void press() => instance.medium();
  static void longPress() => instance.heavy();
  static void select() => instance.selection();
  static void succeed() => instance.success();
  static void warn() => instance.warning();
  static void fail() => instance.error();

  void _feedback(HapticType type) {
    if (!_enabled) return;
    switch (type) {
      case HapticType.light:
        HapticFeedback.lightImpact();
        break;
      case HapticType.medium:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.heavy:
        HapticFeedback.heavyImpact();
        break;
      case HapticType.selection:
        HapticFeedback.selectionClick();
        break;
      case HapticType.success:
        HapticFeedback.lightImpact();
        break;
      case HapticType.warning:
        HapticFeedback.mediumImpact();
        break;
      case HapticType.error:
        HapticFeedback.heavyImpact();
        break;
    }
  }
}

void _h() => HapticService.tap();
