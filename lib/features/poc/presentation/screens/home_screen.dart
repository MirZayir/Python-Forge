import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_button.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/mission.dart';
import '../providers/mission_providers.dart';

/// The professional learning dashboard screen for Python Forge.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load missions from the local repository via Riverpod
    final List<Mission> missions = ref.watch(missionsProvider);
    final Mission? currentMission = missions.isNotEmpty ? missions.first : null;

    return ForgeScaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.large),

            // Welcome Header
            Text(
              'Welcome Back',
              style: AppTypography.headline.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.large),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _StatWidget(label: 'Current Streak', value: '3'),
                _StatWidget(label: 'XP', value: '1250'),
                _StatWidget(label: 'Completed', value: '12'),
              ],
            ),
            const SizedBox(height: AppSpacing.massive),

            // Continue Learning Section
            Text(
              'Continue Learning',
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.medium),

            if (currentMission != null)
              ForgeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentMission.numberLabel,
                      style: AppTypography.body.copyWith(
                        color: AppColors.logicCyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.micro),
                    Text(
                      currentMission.title,
                      style: AppTypography.headline.copyWith(
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      currentMission.description,
                      style: AppTypography.body.copyWith(
                        color: AppColors.syntaxGrey,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),

                    // Progress Indicator
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: 0.5, // Placeholder progress
                            backgroundColor: AppColors.obsidian,
                            color: AppColors.forgeEmber,
                            minHeight: 8.0,
                            borderRadius: BorderRadius.circular(
                              AppRadius.small,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Text(
                          '50%',
                          style: AppTypography.code.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.large),

                    SizedBox(
                      width: double.infinity,
                      child: ForgeButton(
                        label: 'Continue',
                        onPressed: () =>
                            context.push('/mission', extra: currentMission),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.massive),

            // Coming Soon Section
            Text(
              'Coming Soon',
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.medium),
            const _DisabledFeatureCard(title: 'AI Mentor'),
            const SizedBox(height: AppSpacing.small),
            const _DisabledFeatureCard(title: 'Developer Journal'),
            const SizedBox(height: AppSpacing.small),
            const _DisabledFeatureCard(title: 'Projects'),
            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }
}

/// Reusable stat component for the dashboard header.
class _StatWidget extends StatelessWidget {
  final String label;
  final String value;

  const _StatWidget({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.headline.copyWith(
            color: AppColors.logicCyan,
            fontSize: 24.0,
          ),
        ),
        const SizedBox(height: AppSpacing.micro),
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: AppColors.syntaxGrey,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }
}

/// Reusable disabled card for future features.
class _DisabledFeatureCard extends StatelessWidget {
  final String title;

  const _DisabledFeatureCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return ForgeCard(
      backgroundColor: AppColors.obsidian,
      borderColor: AppColors.syntaxGrey.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            color: AppColors.syntaxGrey,
            size: 20.0,
          ),
          const SizedBox(width: AppSpacing.medium),
          Text(
            title,
            style: AppTypography.body.copyWith(
              color: AppColors.syntaxGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
