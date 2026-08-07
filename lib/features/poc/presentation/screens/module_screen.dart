import 'package:flutter/material.dart';

import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/unlock_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/module.dart';
import 'mission_screen.dart';

/// Displays the list of missions for a specific learning module.
class ModuleScreen extends StatefulWidget {
  final Module module;

  const ModuleScreen({super.key, required this.module});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final ProgressManager _progressManager = ProgressManager();
  final UnlockEngine _unlockEngine = UnlockEngine();

  Map<String, bool> _completedStatus = {};
  Map<String, bool> _unlockedStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    Map<String, bool> comp = {};
    Map<String, bool> unlk = {};

    for (var mission in widget.module.missions) {
      comp[mission.id] = await _progressManager.isMissionCompleted(mission.id);
      unlk[mission.id] = await _unlockEngine.isUnlocked(mission);
    }

    if (mounted) {
      setState(() {
        _completedStatus = comp;
        _unlockedStatus = unlk;
        _isLoading = false;
      });
    }
  }

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
          widget.module.title,
          style: AppTypography.title.copyWith(color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.logicCyan),
              ),
            )
          : widget.module.missions.isEmpty
              ? Center(
                  child: Text(
                    'No missions in this module yet.',
                    style: AppTypography.body
                        .copyWith(color: AppColors.syntaxGrey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  itemCount: widget.module.missions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.medium),
                  itemBuilder: (context, index) {
                    final mission = widget.module.missions[index];

                    final isCompleted = _completedStatus[mission.id] ?? false;
                    final isUnlocked = _unlockedStatus[mission.id] ?? false;

                    return GestureDetector(
                      onTap: isUnlocked
                          ? () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MissionScreen(mission: mission),
                                ),
                              );
                              // Refresh mission progression status upon returning to the module screen
                              _loadStatus();
                            }
                          : null,
                      child: ForgeCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mission ${mission.numberLabel}: ${mission.title}',
                                    style: AppTypography.title.copyWith(
                                      color: isUnlocked
                                          ? AppColors.logicCyan
                                          : AppColors.syntaxGrey,
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
                            const SizedBox(width: AppSpacing.medium),
                            if (isCompleted)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.temperGreen,
                                size: 28.0,
                              )
                            else if (!isUnlocked)
                              const Icon(
                                Icons.lock,
                                color: AppColors.syntaxGrey,
                                size: 28.0,
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
