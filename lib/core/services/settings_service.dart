import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../progression/progress_manager.dart';
import 'haptic_service.dart';

/// Service managing user preferences and progress-only resets.
class SettingsService {
  static const String keyHaptics = HapticService.preferenceKey;
  static const String keyFontSize = 'editor_font_size';
  static const double defaultFontSize = 14.0;

  /// Live editor font size so open editors update without being reopened.
  static final ValueNotifier<double> editorFontSize =
      ValueNotifier<double>(defaultFontSize);

  Future<bool> isHapticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(keyHaptics) ?? true;
    HapticService.setEnabled(enabled);
    return enabled;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyHaptics, enabled);
    HapticService.setEnabled(enabled);
  }

  Future<double> getEditorFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final size = prefs.getDouble(keyFontSize) ?? defaultFontSize;
    editorFontSize.value = size;
    return size;
  }

  Future<void> setEditorFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(keyFontSize, size);
    editorFontSize.value = size;
  }

  /// Clears learning progress only. Preferences are intentionally preserved.
  Future<void> resetAllProgress() => ProgressManager().resetProgress();
}
