import 'package:shared_preferences/shared_preferences.dart';

class PreferencesController {
  static const String _keyOnboardingDone = 'onboarding_done';

  /// Cek apakah user sudah pernah melihat onboarding
  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  /// Tandai onboarding sudah selesai
  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, true);
  }

  /// Reset onboarding (untuk keperluan testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOnboardingDone);
  }
}