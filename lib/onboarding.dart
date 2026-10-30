import 'package:shared_preferences/shared_preferences.dart';

/// Remembers whether the first-game hints have been shown on this device.
abstract final class Onboarding {
  static const _seenKey = 'tutorialSeen';

  static Future<bool> isSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_seenKey) ?? false;
    } on Exception {
      // Storage unavailable: skip the hints rather than show them every game.
      return true;
    }
  }

  static Future<void> markSeen() => _write(true);

  /// Shows the hints again in the next game.
  static Future<void> reset() => _write(false);

  static Future<void> _write(bool seen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seenKey, seen);
    } on Exception {
      // Nothing else to do; the hints simply show again next time.
    }
  }
}
