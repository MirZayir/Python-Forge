import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_version_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../../core/widgets/section_title.dart';

/// The minimal foundation screen for Python Forge.
/// Displays basic versioning and initialization status using Riverpod.
class HomeScreen extends ConsumerWidget {
  /// Standard const constructor.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the app version from the provider
    final String version = ref.watch(appVersionProvider);

    return ForgeScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SectionTitle(title: 'Python Forge', subtitle: 'Version $version'),
            const SizedBox(height: AppSpacing.large),
            Text(
              '"Foundation Initialized"',
              style: AppTypography.body.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.syntaxGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
