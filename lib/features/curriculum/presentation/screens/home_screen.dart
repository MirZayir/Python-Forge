import 'package:flutter/material.dart';

import '../../../../core/progression/achievement_catalog.dart';
import '../../../../core/progression/achievement_engine.dart';
import '../../../../core/progression/learning_progress.dart';
import '../../../../core/progression/streak_engine.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../../core/widgets/neubrutalist_card.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../settings/presentation/widgets/settings_modal.dart';
import '../../domain/models/module.dart';
import 'mission_screen.dart';
import 'module_screen.dart';
import 'quick_console_screen.dart';

/// Main dashboard: streak, resume position, overall progress, and curriculum.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LearningProgressService _progressService = LearningProgressService();
  final StreakEngine _streakEngine = StreakEngine();
  final AchievementEngine _achievementEngine = AchievementEngine();
  final SettingsService _settingsService = SettingsService();

  LearningProgress? _progress;
  StreakData? _streakData;
  bool _isLoading = true;
  String? _errorMessage;

  static const List<Color> _moduleColors = [
    AppColors.neuGreen,
    AppColors.neuYellow,
    AppColors.neuPink,
    AppColors.neuPurple,
    AppColors.neuBlue,
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted && !_isLoading) {
      setState(() => _isLoading = true);
    }

    try {
      // Resolve preferences before exposing interactive dashboard controls so
      // the first haptic/editor action cannot use stale defaults.
      await _settingsService.isHapticsEnabled();
      await _settingsService.getEditorFontSize();
      final progress = await _progressService.load();
      final streak = await _streakEngine.getStreakData();

      // Reconcile persisted progress-derived badges on every cold start. This
      // repairs installs interrupted between mission completion and badge save.
      try {
        await _achievementEngine.evaluateAndUnlock(
          AchievementMetrics(
            completedMissionCount: progress.completedMissionCount,
            totalXp: progress.totalXp,
            currentStreak: streak.currentStreak,
          ),
        );
      } catch (_) {
        // Badge persistence must not make the learning dashboard unavailable.
      }

      if (!mounted) return;
      setState(() {
        _progress = progress;
        _streakData = streak;
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

  Future<void> _openModule(Module module) async {
    HapticService.lightImpact();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ModuleScreen(module: module)),
    );
    await _loadDashboard();
  }

  Future<void> _resumeLearning() async {
    final progress = _progress;
    final mission = progress?.nextMission;
    if (progress == null) return;

    HapticService.lightImpact();

    if (mission == null) {
      _showMessage(
          'Every mission is complete. Revisit any module to practise.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => MissionEntryScreen(mission: mission)),
    );
    await _loadDashboard();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderBlack, width: 2.0),
        ),
      ),
    );
  }

  void _showStreakSheet() {
    HapticService.lightImpact();
    final streak = _streakData;
    final currentStreak = streak?.currentStreak ?? 0;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: const BoxDecoration(
            color: AppColors.bgCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: AppColors.borderBlack, width: 3.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.neuYellow,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2.5),
                    ),
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.borderBlack,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentStreak == 1
                              ? '1 Day Streak'
                              : '$currentStreak Day Streak',
                          style: const TextStyle(
                            color: AppColors.borderBlack,
                            fontSize: 22.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Longest streak: ${streak?.longestStreak ?? 0} days',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              const Text(
                "THIS WEEK'S ACTIVITY",
                style: TextStyle(
                  color: AppColors.borderBlack,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = DateTime(
                    startOfWeek.year,
                    startOfWeek.month,
                    startOfWeek.day,
                  ).add(Duration(days: index));
                  final isToday = day.year == now.year &&
                      day.month == now.month &&
                      day.day == now.day;
                  final isActive = streak?.isActiveOn(day) ?? false;

                  return Column(
                    children: [
                      Container(
                        width: 38,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.neuOrange
                              : (isToday
                                  ? AppColors.neuYellow
                                  : AppColors.cardWhite),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.borderBlack, width: 2.0),
                        ),
                        child: Icon(
                          isActive
                              ? Icons.local_fire_department_rounded
                              : Icons.remove_rounded,
                          color: isActive
                              ? Colors.white
                              : AppColors.borderBlack.withValues(alpha: 0.45),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: isToday
                              ? AppColors.borderBlack
                              : const Color(0xFF777777),
                          fontSize: 12.0,
                          fontWeight:
                              isToday ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: AppSpacing.medium),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderBlack, width: 2.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.borderBlack, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        currentStreak > 0
                            ? 'Nice work. Your activity today is recorded.'
                            : 'Complete a mission today to start a streak.',
                        style: const TextStyle(
                          color: AppColors.borderBlack,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _appBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = AppColors.cardWhite,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderBlack, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadowBlack,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.borderBlack, size: 17),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final streakCount = _streakData?.currentStreak ?? 0;
    final isCompactAppBar = MediaQuery.sizeOf(context).width < 420;

    return ForgeScaffold(
      appBar: AppBar(
        titleSpacing: AppSpacing.medium,
        title: Text(
          isCompactAppBar ? 'FORGE' : 'PYTHON FORGE',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: const TextStyle(
            color: AppColors.borderBlack,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          _appBarButton(
            icon: Icons.terminal_rounded,
            tooltip: 'Quick console',
            onTap: () {
              HapticService.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QuickConsoleScreen(),
                ),
              );
            },
          ),
          _appBarButton(
            icon: Icons.settings_rounded,
            tooltip: 'Settings',
            onTap: () {
              HapticService.lightImpact();
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SettingsModal(
                  onProgressReset: _loadDashboard,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: Tooltip(
              message: 'Learning streak',
              child: Semantics(
                button: true,
                label: 'Learning streak, $streakCount days',
                child: InkWell(
                  onTap: _showStreakSheet,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.neuYellow,
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_fire_department_rounded,
                            color: AppColors.borderBlack, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          '$streakCount',
                          style: const TextStyle(
                            color: AppColors.borderBlack,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _appBarButton(
            icon: Icons.person_rounded,
            tooltip: 'Profile',
            onTap: () async {
              HapticService.lightImpact();
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
              await _loadDashboard();
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
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.borderBlack),
          strokeWidth: 3.0,
        ),
      );
    }

    final error = _errorMessage;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.slagRed, size: 42),
              const SizedBox(height: 12),
              const Text(
                'Unable to load curriculum data',
                style: TextStyle(
                  color: AppColors.borderBlack,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.neuYellow,
                  foregroundColor: AppColors.borderBlack,
                  side: const BorderSide(
                      color: AppColors.borderBlack, width: 2.0),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final progress = _progress;
    if (progress == null || progress.modules.isEmpty) {
      return const Center(child: Text('No curriculum modules available.'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.borderBlack,
      backgroundColor: AppColors.neuYellow,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          const Text(
            'Forge code.\nMaster Python.',
            style: TextStyle(
              color: AppColors.borderBlack,
              fontSize: 30.0,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          _buildResumeCard(progress),
          const SizedBox(height: AppSpacing.large),
          _buildOverallProgress(progress),
          const SizedBox(height: 28),
          const Text(
            'My Curriculum',
            style: TextStyle(
              color: AppColors.borderBlack,
              fontSize: 20.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          ...progress.moduleProgress.asMap().entries.map((entry) {
            final index = entry.key;
            final moduleProgress = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: NeubrutalistFolderCard(
                title: moduleProgress.module.title,
                subtitle:
                    '${moduleProgress.completedCount}/${moduleProgress.totalCount} missions complete'
                    '${moduleProgress.module.estimatedHours > 0 ? ' • ${moduleProgress.module.estimatedHours} hrs' : ''}',
                icon: _moduleIcon(index),
                tabColor: moduleProgress.isUnlocked
                    ? _moduleColors[index % _moduleColors.length]
                    : const Color(0xFFD8D5CE),
                onTap: () {
                  if (!moduleProgress.isUnlocked) {
                    HapticService.mediumImpact();
                    _showMessage(
                      'Finish the previous module to unlock ${moduleProgress.module.title}.',
                    );
                    return;
                  }
                  _openModule(moduleProgress.module);
                },
                trailingBadge: _moduleBadge(moduleProgress, index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _moduleBadge(ModuleProgress moduleProgress, int index) {
    if (!moduleProgress.isUnlocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.bgCream,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderBlack, width: 1.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 12, color: AppColors.borderBlack),
            SizedBox(width: 4),
            Text(
              'LOCKED',
              style: TextStyle(
                color: AppColors.borderBlack,
                fontSize: 11.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    if (moduleProgress.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.neuGreen,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderBlack, width: 1.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 12, color: AppColors.borderBlack),
            SizedBox(width: 4),
            Text(
              'DONE',
              style: TextStyle(
                color: AppColors.borderBlack,
                fontSize: 11.0,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderBlack, width: 1.8),
      ),
      child: Text(
        'MOD ${(index + 1).toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: AppColors.borderBlack,
          fontSize: 11.0,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildResumeCard(LearningProgress progress) {
    final mission = progress.nextMission;
    final moduleTitle = progress.nextModule?.title ?? 'Curriculum complete';
    final isComplete = mission == null;

    return Semantics(
      button: true,
      label: isComplete
          ? 'All missions complete'
          : 'Resume learning, ${mission.title}',
      child: InkWell(
        onTap: _resumeLearning,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: isComplete ? AppColors.neuGreen : AppColors.neuYellow,
            borderRadius: BorderRadius.circular(20),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.borderBlack, width: 1.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isComplete
                              ? Icons.emoji_events_rounded
                              : Icons.bolt_rounded,
                          color: AppColors.borderBlack,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isComplete ? 'ALL COMPLETE' : 'RESUME LEARNING',
                          style: const TextStyle(
                            color: AppColors.borderBlack,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2.0),
                    ),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.borderBlack, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                isComplete ? 'Curriculum complete' : mission.title,
                style: const TextStyle(
                  color: AppColors.borderBlack,
                  fontSize: 21.0,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isComplete
                    ? 'Revisit any module to practise again'
                    : '$moduleTitle • Tap to continue',
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgress(LearningProgress progress) {
    return Container(
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'OVERALL PROGRESS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  '${progress.completedMissionCount}/${progress.totalMissionCount} • Lvl ${progress.level}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.borderBlack,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.bgCream,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderBlack, width: 2.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.completionPercent,
                backgroundColor: Colors.transparent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.neuYellow),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${progress.totalXp} XP earned',
            style: const TextStyle(
              color: AppColors.borderBlack,
              fontSize: 13.0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  IconData _moduleIcon(int index) {
    const icons = [
      Icons.terminal_rounded,
      Icons.alt_route_rounded,
      Icons.loop_rounded,
      Icons.dataset_rounded,
      Icons.functions_rounded,
      Icons.category_rounded,
      Icons.report_problem_rounded,
      Icons.extension_rounded,
    ];
    return icons[index % icons.length];
  }
}
