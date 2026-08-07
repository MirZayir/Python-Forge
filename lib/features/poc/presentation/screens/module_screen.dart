import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/module.dart';
import 'mission_screen.dart';

/// Displays the list of missions for a specific learning module.
class ModuleScreen extends StatelessWidget {
  final Module module;

  const ModuleScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          module.title,
          style: AppTypography.title.copyWith(color: Colors.white),
        ),
      ),
      body: module.missions.isEmpty
          ? Center(
              child: Text(
                'No missions in this module yet.',
                style: AppTypography.body.copyWith(color: AppColors.syntaxGrey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.medium),
              itemCount: module.missions.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.medium),
              itemBuilder: (context, index) {
                final mission = module.missions[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MissionScreen(mission: mission),
                      ),
                    );
                  },
                  child: ForgeCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mission ${mission.numberLabel}: ${mission.title}',
                          style: AppTypography.title.copyWith(
                            color: AppColors.logicCyan,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          mission.objective,
                          style: AppTypography.body.copyWith(
                            color: AppColors.syntaxGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
