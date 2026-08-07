import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/mission.dart';
import '../providers/mission_providers.dart';

/// The professional learning dashboard screen for Python Forge.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load the full list of missions from the provider
    final List<Mission> missions = ref.watch(missionsProvider);

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

            // Curriculum Section
            Text(
              'Curriculum',
              style: AppTypography.title.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpacing.medium),

            // Render the dynamically loaded vertical list of missions
            if (missions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.large),
                  child: CircularProgressIndicator(color: AppColors.forgeEmber),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: missions.length,
                itemBuilder: (context, index) {
                  return _MissionListCard(mission: missions[index]);
                },
              ),

            const SizedBox(height: AppSpacing.massive),
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

/// A dedicated Forge card for displaying individual missions in a vertical list.
class _MissionListCard extends StatelessWidget {
  final Mission mission;

  const _MissionListCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = mission.isUnlocked;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.6,
        child: InkWell(
          onTap: isUnlocked
              ? () => context.push('/mission', extra: mission)
              : null,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          // We wrap the card in InkWell to provide native material ripple feedback
          // when tapping an unlocked mission.
          child: ForgeCard(
            backgroundColor: AppColors.obsidian,
            borderColor: isUnlocked
                ? AppColors.forgeEmber.withValues(alpha: 0.5)
                : AppColors.syntaxGrey.withValues(alpha: 0.3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission.numberLabel.toUpperCase(),
                        style: AppTypography.body.copyWith(
                          color: isUnlocked
                              ? AppColors.logicCyan
                              : AppColors.syntaxGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        mission.title,
                        style: AppTypography.headline.copyWith(
                          color: Colors.white,
                          fontSize: 18.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.micro),
                      Text(
                        mission.description,
                        style: AppTypography.body.copyWith(
                          color: AppColors.syntaxGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                if (!isUnlocked)
                  const Icon(
                    Icons.lock_outline,
                    color: AppColors.syntaxGrey,
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.logicCyan,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
