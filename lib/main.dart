import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Application entry point.
void main() {
  runApp(
    // ProviderScope initializes Riverpod at the root of the application hierarchy.
    const ProviderScope(child: PythonForgeApp()),
  );
}

/// The root application widget.
/// Configured with a pure Material 3 dark theme foundation and GoRouter.
class PythonForgeApp extends ConsumerWidget {
  /// Standard const constructor.
  const PythonForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the GoRouter configuration from Riverpod
    final goRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Python Forge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}
