import 'package:flutter/material.dart';

import '../../../../core/progression/learning_progress.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/mission.dart';
import '../../domain/models/module.dart';
import 'mission_screen.dart';

/// Lists the missions of a module with real completion and lock state.
class ModuleScreen extends StatefulWidget {
  final Module module;

  const ModuleScreen({super.key, required this.module});

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  final LearningProgressService _progressService = LearningProgressService();

  LearningProgress? _progress;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await _progressService.load();
      if (!mounted) return;
      setState(() {
        _progress = progress;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openMission(Mission mission, bool isUnlocked) async {
    if (!isUnlocked) {
      HapticService.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Complete the previous mission to unlock this one.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderBlack, width: 2.0),
          ),
        ),
      );
      return;
    }

    HapticService.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => MissionEntryScreen(mission: mission)),
    );
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final completedCount = progress == null
        ? 0
        : widget.module.missions
            .where((mission) => progress.isMissionCompleted(mission.id))
            .length;

    return ForgeScaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Tooltip(
            message: 'Back',
            child: Semantics(
              button: true,
              label: 'Back',
              child: InkWell(
                onTap: () {
                  HapticService.lightImpact();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowBlack,
                        offset: Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: AppColors.borderBlack, size: 20),
                ),
              ),
            ),
          ),
        ),
        title: Text(
          widget.module.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.borderBlack,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.borderBlack),
              ),
            )
          : _errorMessage != null
              ? _buildErrorBody()
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.module.missions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildModuleSummary(completedCount);
                    }
                    final mission = widget.module.missions[index - 1];
                    final isCompleted =
                        progress?.isMissionCompleted(mission.id) ?? false;
                    final isUnlocked =
                        progress?.isMissionUnlocked(mission.id) ?? false;
                    return _buildMissionCard(
                      mission: mission,
                      missionNumber: index,
                      isCompleted: isCompleted,
                      isUnlocked: isUnlocked,
                    );
                  },
                ),
    );
  }

  Widget _buildErrorBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.slagRed, size: 42),
            const SizedBox(height: AppSpacing.medium),
            const Text(
              'Unable to load module progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.borderBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              _errorMessage ?? 'Unknown progress error.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.borderBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            ElevatedButton(
              onPressed: _loadProgress,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleSummary(int completedCount) {
    final total = widget.module.missions.length;
    final percent = total == 0 ? 0.0 : completedCount / total;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.large),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.module.description,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $total complete',
                style: const TextStyle(
                  color: AppColors.borderBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${(percent * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.borderBlack,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.bgCream,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderBlack, width: 2.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.transparent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.neuGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard({
    required Mission mission,
    required int missionNumber,
    required bool isCompleted,
    required bool isUnlocked,
  }) {
    final typeLabel = switch (mission.type) {
      MissionType.code => 'CODE',
      MissionType.mcq => 'QUIZ',
      MissionType.fillInBlank => 'FILL IN',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Semantics(
        button: true,
        enabled: isUnlocked,
        label: '$typeLabel mission $missionNumber, ${mission.title}'
            '${isCompleted ? ', completed' : ''}'
            '${isUnlocked ? '' : ', locked'}',
        child: InkWell(
          onTap: () => _openMission(mission, isUnlocked),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.cardWhite : const Color(0xFFF0EEE8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderBlack, width: 2.5),
              boxShadow: isUnlocked
                  ? const [
                      BoxShadow(
                        color: AppColors.shadowBlack,
                        offset: Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.neuGreen
                        : (isUnlocked
                            ? AppColors.neuYellow
                            : const Color(0xFFDCD9D2)),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.0),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.borderBlack, size: 22)
                        : (isUnlocked
                            ? Text(
                                '$missionNumber',
                                style: const TextStyle(
                                  color: AppColors.borderBlack,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              )
                            : const Icon(Icons.lock_rounded,
                                color: AppColors.borderBlack, size: 18)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.bgCream,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.borderBlack, width: 1.4),
                            ),
                            child: Text(
                              typeLabel,
                              style: const TextStyle(
                                color: AppColors.borderBlack,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              mission.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.borderBlack,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUnlocked
                      ? Icons.play_arrow_rounded
                      : Icons.lock_outline_rounded,
                  color: isUnlocked
                      ? AppColors.borderBlack
                      : AppColors.borderBlack.withValues(alpha: 0.4),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
