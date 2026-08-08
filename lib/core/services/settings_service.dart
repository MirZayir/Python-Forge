import 'package:shared_preferences/shared_preferences.dart';

/// Service managing user application preferences and progress resets.
class SettingsService {
  static const String _keyHaptics = 'haptics_enabled';
  static const String _keyFontSize = 'editor_font_size';

  Future<bool> isHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHaptics) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHaptics, enabled);
  }

  Future<double> getEditorFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFontSize) ?? 14.0;
  }

  Future<void> setEditorFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFontSize, size);
  }

  Future<void> resetAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
