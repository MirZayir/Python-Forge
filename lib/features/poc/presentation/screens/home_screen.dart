import 'package:flutter/material.dart';

import '../../../../core/progression/progress_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
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
  final CurriculumRepository _repository = CurriculumRepository();
  final ProgressManager _progressManager = ProgressManager();

  Curriculum? _curriculum;
  Map<String, int> _completedMissionsPerModule = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Asynchronously loads curriculum and completion progress via ProgressManager.
  Future<void> _loadData() async {
    try {
      final curriculum = await _repository.getCurriculum();

      Map<String, int> completedCounts = {};

      for (var module in curriculum.modules) {
        int count = 0;
        for (var mission in module.missions) {
          final isCompleted =
              await _progressManager.isMissionCompleted(mission.id);
          if (isCompleted) {
            count++;
          }
        }
        completedCounts[module.moduleId] = count;
      }

      if (mounted) {
        setState(() {
          _curriculum = curriculum;
          _completedMissionsPerModule = completedCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.logicCyan),
        ),
      );
    } else if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Text(
            'Failed to load curriculum: $_errorMessage',
            style: AppTypography.body.copyWith(color: AppColors.slagRed),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_curriculum == null || _curriculum!.modules.isEmpty) {
      return Center(
        child: Text(
          'No modules found.',
          style: AppTypography.body.copyWith(color: AppColors.syntaxGrey),
        ),
      );
    }

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
              itemCount: _curriculum!.modules.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.medium),
              itemBuilder: (context, index) {
                final module = _curriculum!.modules[index];

                final int completedMissions =
                    _completedMissionsPerModule[module.moduleId] ?? 0;
                final int totalMissions = module.missions.length;
                final double progress =
                    totalMissions == 0 ? 0 : completedMissions / totalMissions;

                return GestureDetector(
                  onTap: () async {
                    // Wait for the user to return from the module navigation path
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ModuleScreen(module: module),
                      ),
                    );
                    // Refresh progress immediately upon returning to the Home Screen
                    _loadData();
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
                          borderRadius: BorderRadius.circular(AppRadius.small),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppColors.obsidian,
                            valueColor: const AlwaysStoppedAnimation<Color>(
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
  }
}
