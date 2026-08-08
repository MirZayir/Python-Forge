import 'package:flutter/material.dart';

import '../../../../core/progression/streak_engine.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../../core/widgets/neubrutalist_card.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../settings/presentation/widgets/settings_modal.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/curriculum.dart';
import 'module_screen.dart';
import 'quick_console_screen.dart';

/// HomeScreen transformed into Neubrutalism style with interactive Console, Streak, and Hero Banner.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CurriculumRepository _repository = CurriculumRepository();
  final StreakEngine _streakEngine = StreakEngine();

  Curriculum? _curriculum;
  StreakData? _streakData;
  bool _isLoading = true;
  String? _errorMessage;

  final List<Color> _folderColors = [
    AppColors.neuGreen,
    AppColors.neuYellow,
    AppColors.neuPink,
    AppColors.neuPurple,
    AppColors.neuBlue,
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final curriculum = await _repository.getCurriculum();
      final streak = await _streakEngine.getStreakData();

      if (mounted) {
        setState(() {
          _curriculum = curriculum;
          _streakData = streak;
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

  void _showStreakActivityModal() {
    HapticService.lightImpact();
    final streak = _streakData?.currentStreak ?? 0;
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.bgCream,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppColors.borderBlack, width: 3.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neuYellow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.borderBlack, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.borderBlack,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$streak Day Streak!',
                            style: const TextStyle(
                              color: AppColors.borderBlack,
                              fontSize: 22.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Active Learning Tracker',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticService.lightImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.borderBlack, width: 2.0),
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.borderBlack),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'THIS WEEK\'S ACTIVITY',
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
                  final isToday = index == todayIndex;
                  final isActive = index <= todayIndex && streak > 0;

                  return Column(
                    children: [
                      Container(
                        width: 40,
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
                              : Icons.check_rounded,
                          color: isActive
                              ? Colors.white
                              : (isToday ? AppColors.borderBlack : Colors.grey),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        days[index],
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
              const SizedBox(height: 20),
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
                        streak > 0
                            ? 'Great job! You logged learning activity today.'
                            : 'Complete a mission today to extend your flame streak!',
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

  @override
  Widget build(BuildContext context) {
    final streakCount = _streakData?.currentStreak ?? 0;

    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 12.0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                HapticService.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const QuickConsoleScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
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
                child: const Icon(
                  Icons.terminal_rounded,
                  color: AppColors.borderBlack,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Python Forge',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.borderBlack,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Settings Gear Button
          GestureDetector(
            onTap: () {
              HapticService.lightImpact();
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) => SettingsModal(
                  onProgressReset: () {
                    _loadDashboardData();
                  },
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(7),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
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
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.borderBlack,
                size: 18,
              ),
            ),
          ),

          // Streak Badge Button
          GestureDetector(
            onTap: _showStreakActivityModal,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.neuYellow,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: AppColors.borderBlack,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streakCount',
                      style: const TextStyle(
                        color: AppColors.borderBlack,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Profile Button
          GestureDetector(
            onTap: () {
              HapticService.lightImpact();
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  )
                  .then((_) => _loadDashboardData());
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
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
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.borderBlack,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: AppColors.bgCream,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.borderBlack),
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
      return const Center(
        child: Text('No curriculum modules available.'),
      );
    }

    final modules = _curriculum!.modules;
    final firstModule = modules.first;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.borderBlack,
      backgroundColor: AppColors.neuYellow,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          // Bold Neubrutalist Title Banner
          const Text(
            'Forge code.\nMaster Python.',
            style: TextStyle(
              color: AppColors.borderBlack,
              fontSize: 32.0,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 20),

          // Scaled-Up Hero Resume Learning Banner Card
          GestureDetector(
            onTap: () {
              HapticService.lightImpact();
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => ModuleScreen(module: firstModule),
                    ),
                  )
                  .then((_) => _loadDashboardData());
            },
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.neuYellow,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.borderBlack, width: 1.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.bolt_rounded,
                                color: AppColors.borderBlack, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'RESUME LEARNING',
                              style: TextStyle(
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
                          border: Border.all(
                              color: AppColors.borderBlack, width: 2.0),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.borderBlack,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    firstModule.title,
                    style: const TextStyle(
                      color: AppColors.borderBlack,
                      fontSize: 22.0,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${firstModule.missions.length} Missions • Tap to continue journey',
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
          const SizedBox(height: 28),

          // "My Curriculum" Section Label
          const Text(
            'My Curriculum',
            style: TextStyle(
              color: AppColors.borderBlack,
              fontSize: 20.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),

          // Folder-Tab Cards List
          ...modules.asMap().entries.map((entry) {
            final index = entry.key;
            final module = entry.value;
            final tabColor = _folderColors[index % _folderColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: NeubrutalistFolderCard(
                title: module.title,
                subtitle:
                    '${module.missions.length} Missions • ${module.estimatedHours} hrs',
                icon: _getModuleIcon(index),
                tabColor: tabColor,
                onTap: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => ModuleScreen(module: module),
                        ),
                      )
                      .then((_) => _loadDashboardData());
                },
                trailingBadge: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCream,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 1.8),
                  ),
                  child: Text(
                    'MOD 0${index + 1}',
                    style: const TextStyle(
                      color: AppColors.borderBlack,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getModuleIcon(int index) {
    switch (index) {
      case 0:
        return Icons.terminal_rounded;
      case 1:
        return Icons.alt_route_rounded;
      case 2:
        return Icons.loop_rounded;
      case 3:
        return Icons.dataset_rounded;
      case 4:
        return Icons.code_rounded;
      case 5:
        return Icons.category_rounded;
      default:
        return Icons.terminal_rounded;
    }
  }
}
