import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Central theme configuration for Python Forge.
///
/// The product UI is a light cream neubrutalist system. The theme must match
/// it, otherwise Material paints dark surfaces behind cream screens and shows
/// black bands during navigation and scroll overscroll.
abstract class AppTheme {
  static ThemeData get forgeTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgCream,
      canvasColor: AppColors.bgCream,
      colorScheme: const ColorScheme.light(
        primary: AppColors.neuYellow,
        onPrimary: AppColors.borderBlack,
        secondary: AppColors.neuGreen,
        onSecondary: AppColors.borderBlack,
        surface: AppColors.cardWhite,
        onSurface: AppColors.borderBlack,
        error: AppColors.slagRed,
        onError: Colors.white,
      ),
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgCream,
        foregroundColor: AppColors.borderBlack,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.bgCream,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: AppColors.neuYellow,
        contentTextStyle: const TextStyle(
          color: AppColors.borderBlack,
          fontWeight: FontWeight.w700,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.borderBlack,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.borderBlack,
        selectionHandleColor: AppColors.borderBlack,
      ),
      splashFactory: NoSplash.splashFactory,
    );
  }

  /// Retained for compatibility with older references.
  static ThemeData get darkTheme => forgeTheme;
}
