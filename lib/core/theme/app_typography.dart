import 'package:flutter/material.dart';

/// Typography constants for Python Forge.
abstract class AppTypography {
  static const String uiFontFamily = 'Inter';
  static const String codeFontFamily = 'JetBrains Mono';

  static const TextStyle headline = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 28.0,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle title = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle body = TextStyle(
    fontFamily: uiFontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle code = TextStyle(
    fontFamily: codeFontFamily,
    fontSize: 14.0,
    fontWeight: FontWeight.normal,
  );
}
