import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/forge_button.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../../core/widgets/section_title.dart';

/// Placeholder screen for the Mission Crucible (Code Editor).
class MissionScreen extends ConsumerWidget {
  const MissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SectionTitle(
              title: 'Mission Crucible',
              subtitle: 'Code Editor & Visualizer Placeholder',
            ),
            const SizedBox(height: AppSpacing.large),
            ForgeButton(
              label: 'Abort Mission',
              isPrimary: false,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}
