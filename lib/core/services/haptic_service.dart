import 'package:flutter/services.dart';

/// Centralized Haptic Feedback engine for tactile Neubrutalist UI interactions.
class HapticService {
  /// Subtle vibration for regular card/button taps
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium vibration for submitting answers and tab selections
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy vibration for runtime errors or important alerts
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Double vibration pattern for mission completion celebrations
  static void successPattern() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  /// Rapid light feedback for keyboard accessory bar actions
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }
}
