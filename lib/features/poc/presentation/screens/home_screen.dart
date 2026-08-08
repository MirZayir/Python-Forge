import 'package:flutter/material.dart';

import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/xp_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/curriculum.dart';
import '../../domain/models/mission.dart';
import '../../domain/models/module.dart';
import 'module_screen.dart';

/// Main dashboard with Matte Cream Bento Container Surfaces (#E8D8C9).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Vintage Retro Matte Palette
  static const Color _bgDark = Color(0xFF121212);
  static const Color _creamMatte = Color(0xFFE8D8C9);
  static const Color _slateBlue = Color(0xFF4B607F);
  static const Color _retroOrange = Color(0xFFF3701E);
  static const Color _textDark = Color(0xFF18181A);
  static const Color _textMutedDark = Color(0xFF5A5A60);

  final CurriculumRepository _repository = CurriculumRepository();
  final ProgressManager _progressManager = ProgressManager();

  Curriculum? _curriculum;
  Map<String, int> _completedMissionsPerModule = {};
  int _totalCompletedMissions = 0;
  int _totalXp = 0;
  int _userLevel = 1;

  Module? _continueModule;
  Mission? _continueMission;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final curriculum = await _repository.getCurriculum();

      Map<String, int> completedCounts = {};
      int totalCompleted = 0;
      int accumulatedXp = 0;

      Module? activeModule;
      Mission? activeMission;

      for (var module in curriculum.modules) {
        int count = 0;
        for (var mission in module.missions) {
          final isCompleted =
              await _progressManager.isMissionCompleted(mission.id);
          if (isCompleted) {
            count++;
            accumulatedXp += XpManager.rewardFor(mission);
          } else if (activeMission == null) {
            activeModule = module;
            activeMission = mission;
          }
        }
        completedCounts[module.moduleId] = count;
        totalCompleted += count;
      }

      final level = (accumulatedXp / 100).floor() + 1;

      if (mounted) {
        setState(() {
          _curriculum = curriculum;
          _completedMissionsPerModule = completedCounts;
          _totalCompletedMissions = totalCompleted;
          _totalXp = accumulatedXp;
          _userLevel = level;
          _continueModule = activeModule ??
              (curriculum.modules.isNotEmpty ? curriculum.modules.first : null);
          _continueMission = activeMission ??
              (_continueModule?.missions.isNotEmpty == true
                  ? _continueModule!.missions.first
                  : null);
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning 👋';
    } else if (hour < 17) {
      return 'Good Afternoon 👋';
    } else {
      return 'Good Evening 👋';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: _retroOrange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Text(
              'Python Forge',
              style: AppTypography.title.copyWith(
                color: _creamMatte,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.medium),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: _creamMatte,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: _textDark, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_retroOrange),
        ),
      );
    } else if (_errorMessage != null) {
      return Center(
        key: const ValueKey('error'),
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
        key: const ValueKey('empty'),
        child: Text(
          'No modules found.',
          style: AppTypography.body.copyWith(color: _creamMatte),
        ),
      );
    }

    return SingleChildScrollView(
      key: const ValueKey('content'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large, vertical: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Greeting Header Card Wrapper
          _buildGreetingHeader(),
          const SizedBox(height: AppSpacing.large),

          // Hero Continue Bento Card
          if (_continueModule != null && _continueMission != null) ...[
            _buildHeroBentoCard(),
            const SizedBox(height: AppSpacing.large),
          ],

          // Bento Progress Section
          _buildBentoProgressSection(),
          const SizedBox(height: AppSpacing.large),

          // Bento Curriculum Section
          _buildBentoCurriculumSection(),
          const SizedBox(height: AppSpacing.large),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _creamMatte,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreeting(),
            style: AppTypography.title.copyWith(
              color: _textDark,
              fontSize: 26.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep building your coding streak today.',
            style: AppTypography.body.copyWith(
              color: _textMutedDark,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBentoCard() {
    final module = _continueModule!;
    final mission = _continueMission!;
    final completedInModule = _completedMissionsPerModule[module.moduleId] ?? 0;
    final totalInModule = module.missions.length;
    final progress =
        totalInModule == 0 ? 0.0 : completedInModule / totalInModule;

    return Container(
      decoration: BoxDecoration(
        color: _creamMatte,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(32),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ModuleScreen(module: module),
              ),
            );
            _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _bgDark,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'CONTINUE LEARNING',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.body.copyWith(
                            color: _creamMatte,
                            fontSize: 10.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _slateBlue.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}% Done',
                        style: AppTypography.code.copyWith(
                          color: _slateBlue,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  module.title.toUpperCase(),
                  style: AppTypography.body.copyWith(
                    color: _slateBlue,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mission ${mission.numberLabel}: ${mission.title}',
                  style: AppTypography.title.copyWith(
                    color: _textDark,
                    fontSize: 22.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black.withValues(alpha: 0.08),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_retroOrange),
                    minHeight: 10.0,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: _retroOrange,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _retroOrange.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Resume Mission',
                          style: AppTypography.title.copyWith(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBentoProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: AppTypography.title.copyWith(
            color: _creamMatte,
            fontSize: 20.0,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            // Left Level Card Surface (Matte Cream)
            Expanded(
              flex: 5,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _creamMatte,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _slateBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.military_tech_rounded,
                            color: _slateBlue,
                            size: 20,
                          ),
                        ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _retroOrange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'LEVEL',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.body.copyWith(
                                color: Colors.white,
                                fontSize: 9.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Lvl $_userLevel',
                      style: AppTypography.title.copyWith(
                        color: _textDark,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Current Rank',
                      style: AppTypography.body.copyWith(
                        color: _textMutedDark,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),

            // Right Stacked Small Bento Cards
            Expanded(
              flex: 6,
              child: Column(
                children: [
                  // XP Matte Cream Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: _creamMatte,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _retroOrange.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: _retroOrange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_totalXp',
                                style: AppTypography.title.copyWith(
                                  color: _textDark,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Total XP',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  color: _textMutedDark,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),

                  // Missions Done Matte Cream Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: _creamMatte,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _slateBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: _slateBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$_totalCompletedMissions',
                                style: AppTypography.title.copyWith(
                                  color: _textDark,
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Missions Done',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  color: _textMutedDark,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoCurriculumSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Curriculum',
          style: AppTypography.title.copyWith(
            color: _creamMatte,
            fontSize: 20.0,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _curriculum!.modules.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.medium),
          itemBuilder: (context, index) {
            final module = _curriculum!.modules[index];
            final completedMissions =
                _completedMissionsPerModule[module.moduleId] ?? 0;
            final totalMissions = module.missions.length;
            final progress =
                totalMissions == 0 ? 0.0 : completedMissions / totalMissions;

            return Container(
              decoration: BoxDecoration(
                color: _creamMatte,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ModuleScreen(module: module),
                      ),
                    );
                    _loadData();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _slateBlue,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: _creamMatte,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.medium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module.title,
                                    style: AppTypography.title.copyWith(
                                      color: _textDark,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (module.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      module.description,
                                      style: AppTypography.body.copyWith(
                                        color: _textMutedDark,
                                        fontSize: 13.0,
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: _textMutedDark,
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completedMissions of $totalMissions Completed',
                              style: AppTypography.body.copyWith(
                                color: _textMutedDark,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: AppTypography.code.copyWith(
                                color:
                                    progress == 1.0 ? _retroOrange : _slateBlue,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                Colors.black.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0 ? _retroOrange : _slateBlue,
                            ),
                            minHeight: 8.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
