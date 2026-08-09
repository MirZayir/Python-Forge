import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized haptic feedback that honours the user preference.
class HapticService {
  static const String preferenceKey = 'haptics_enabled';
  static bool _enabled = true;

  static bool get isEnabled => _enabled;

  /// Keeps the cached preference in sync with storage.
  static Future<void> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(preferenceKey) ?? true;
  }

  /// Applied immediately when the user toggles the setting.
  static void setEnabled(bool enabled) => _enabled = enabled;

  static void lightImpact() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  static void mediumImpact() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  static void heavyImpact() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  static Future<void> successPattern() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  static void selectionClick() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }
}
