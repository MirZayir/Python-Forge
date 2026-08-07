import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/curriculum.dart';
import 'module_screen.dart';

/// The main dashboard screen displaying available learning modules.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<Curriculum> _curriculumFuture;
  final CurriculumRepository _repository = CurriculumRepository();

  @override
  void initState() {
    super.initState();
    _curriculumFuture = _repository.getCurriculum();
  }

  @override
  Widget build(BuildContext context) {
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Python Forge',
          style: AppTypography.title.copyWith(color: Colors.white),
        ),
      ),
      body: FutureBuilder<Curriculum>(
        future: _curriculumFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.logicCyan),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Text(
                  'Failed to load curriculum: ${snapshot.error}',
                  style: AppTypography.body.copyWith(color: AppColors.slagRed),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.modules.isEmpty) {
            return Center(
              child: Text(
                'No modules found.',
                style: AppTypography.body.copyWith(color: AppColors.syntaxGrey),
              ),
            );
          }

          final curriculum = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Curriculum',
                  style: AppTypography.title.copyWith(
                    color: Colors.white,
                    fontSize: 24.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Expanded(
                  child: ListView.separated(
                    itemCount: curriculum.modules.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.medium),
                    itemBuilder: (context, index) {
                      final module = curriculum.modules[index];

                      // For now, hardcode mock completions based on requirements.
                      // Future iterations will pull this from SharedPreferences.
                      final int completedMissions = index == 0 ? 2 : 0;
                      final int totalMissions = module.missions.length;
                      final double progress = totalMissions == 0
                          ? 0
                          : completedMissions / totalMissions;

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ModuleScreen(module: module),
                            ),
                          );
                        },
                        child: ForgeCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                module.title,
                                style: AppTypography.title.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              if (module.description.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.micro),
                                Text(
                                  module.description,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.syntaxGrey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.small),
                              Text(
                                '$completedMissions / $totalMissions missions completed',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.syntaxGrey,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.medium),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.small),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: AppColors.obsidian,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    AppColors.temperGreen,
                                  ),
                                  minHeight: 8.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
