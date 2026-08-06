import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/poc/presentation/screens/home_screen.dart';

/// Application entry point.
void main() {
  runApp(
    // ProviderScope initializes Riverpod at the root of the application hierarchy.
    const ProviderScope(child: PythonForgeApp()),
  );
}

/// The root application widget.
/// Configured with a pure Material 3 dark theme foundation.
class PythonForgeApp extends StatelessWidget {
  /// Standard const constructor.
  const PythonForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Python Forge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange, // Aligns with the Forge Ember concept
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
