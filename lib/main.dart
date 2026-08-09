import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Application entry point.
void main() {
  runApp(
    const ProviderScope(
      child: PythonForgeApp(),
    ),
  );
}

/// Root application widget.
///
/// The router has one explicit cold-start location: `/`, which renders the
/// home screen. Mission screens are only reachable through an intentional
/// navigation action or a valid typed route extra.
class PythonForgeApp extends ConsumerWidget {
  const PythonForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Python Forge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forgeTheme,
      routerConfig: router,
    );
  }
}
