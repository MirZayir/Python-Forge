import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Central theme configuration for Python Forge.
abstract class AppTheme {
  /// Defines the dark theme for Python Forge matching Material 3 and the Design Bible.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.obsidian,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.forgeEmber,
        secondary: AppColors.logicCyan,
        surface: AppColors.crucibleGrey,
        error: AppColors.slagRed,
        onPrimary: AppColors.obsidian,
        onSecondary: AppColors.obsidian,
        onSurface: Colors.white,
        onError: Colors.white,
      ),
    );
  }
}
