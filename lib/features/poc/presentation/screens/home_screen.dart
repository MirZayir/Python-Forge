import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_button.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../../core/widgets/section_title.dart';

/// The primary dashboard screen for Python Forge.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ForgeScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.large),
          const SectionTitle(title: 'Python Forge'),
          const SizedBox(height: AppSpacing.massive),
          Text(
            'Continue Learning',
            style: AppTypography.title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.medium),
          ForgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mission 1',
                  style: AppTypography.body.copyWith(
                    color: AppColors.logicCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  'Hello, Python',
                  style: AppTypography.headline.copyWith(
                    color: Colors.white,
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Learn what Python is and print your first line of code.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.syntaxGrey,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                SizedBox(
                  width: double.infinity,
                  child: ForgeButton(
                    label: 'Start Mission',
                    onPressed: () => context.push('/mission'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
