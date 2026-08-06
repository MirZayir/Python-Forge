import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_version_provider.dart';

/// The minimal foundation screen for Python Forge.
/// Displays basic versioning and initialization status using Riverpod.
class HomeScreen extends ConsumerWidget {
  /// Standard const constructor.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    // Watch the app version from the provider
    final String version = ref.watch(appVersionProvider);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Python Forge',
              style: textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text('Version $version', style: textTheme.titleMedium),
            const SizedBox(height: 32.0),
            Text(
              '"Foundation Initialized"',
              style: textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
