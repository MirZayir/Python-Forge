import 'package:flutter/material.dart';

import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/xp_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/curriculum.dart';
import '../../domain/models/mission.dart';
import '../../domain/models/module.dart';
import 'module_screen.dart';

/// The main dashboard screen displaying available learning modules and overall learner progress.
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

  /// Asynchronously loads curriculum and completion progress via ProgressManager.
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
                color: const Color(0xFFC3F53C), // Accent Lime
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFF111215),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Text(
              'Python Forge',
              style: AppTypography.title.copyWith(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
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
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22242A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: const Icon(Icons.person_outline_rounded,
                      color: Colors.white, size: 20),
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
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFC3F53C)),
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
          style: AppTypography.body.copyWith(color: AppColors.syntaxGrey),
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
          // Greeting Header
          _buildGreetingHeader(),
          const SizedBox(height: AppSpacing.large),

          // Bento Section 1: Hero Continue Card
          if (_continueModule != null && _continueMission != null) ...[
            _buildBentoHeroCard(),
            const SizedBox(height: AppSpacing.large),
          ],

          // Bento Section 2: Progress Grid
          _buildBentoProgressGrid(),
          const SizedBox(height: AppSpacing.large),

          // Bento Section 3: Curriculum List
          _buildBentoCurriculumList(),
          const SizedBox(height: AppSpacing.large),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: AppTypography.title.copyWith(
            color: Colors.white,
            fontSize: 28.0,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Keep pushing forward to master Python.',
          style: AppTypography.body.copyWith(
            color: const Color(0xFFA0A5B5),
            fontSize: 15.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBentoHeroCard() {
    final module = _continueModule!;
    final mission = _continueMission!;
    final completedInModule = _completedMissionsPerModule[module.moduleId] ?? 0;
    final totalInModule = module.missions.length;
    final progress =
        totalInModule == 0 ? 0.0 : completedInModule / totalInModule;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFC3F53C), // Vibrant Neo-Bento Accent Container
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC3F53C).withOpacity(0.2),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
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
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111215),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'CONTINUE LEARNING',
                        style: AppTypography.body.copyWith(
                          color: const Color(0xFFC3F53C),
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}% Done',
                        style: AppTypography.code.copyWith(
                          color: const Color(0xFF111215),
                          fontSize: 12.0,
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
                    color: const Color(0xFF333820),
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mission ${mission.numberLabel}: ${mission.title}',
                  style: AppTypography.title.copyWith(
                    color: const Color(0xFF111215),
                    fontSize: 24.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black.withOpacity(0.12),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF111215)),
                    minHeight: 10.0,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111215),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Resume Mission',
                          style: AppTypography.title.copyWith(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            color: Colors.white, size: 20),
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

  Widget _buildBentoProgressGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: AppTypography.title.copyWith(
            color: Colors.white,
            fontSize: 20.0,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            Expanded(
              child: _buildBentoTile(
                label: 'Level',
                value: 'Lvl $_userLevel',
                icon: Icons.military_tech_rounded,
                bgColor: const Color(0xFF221C28),
                accentColor: const Color(0xFFFF9F43),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: _buildBentoTile(
                label: 'Total XP',
                value: '$_totalXp',
                icon: Icons.bolt_rounded,
                bgColor: const Color(0xFF1B242D),
                accentColor: const Color(0xFF54A0FF),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: _buildBentoTile(
                label: 'Missions',
                value: '$_totalCompletedMissions',
                icon: Icons.check_circle_rounded,
                bgColor: const Color(0xFF182620),
                accentColor: const Color(0xFF1DD1A1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoTile({
    required String label,
    required String value,
    required IconData icon,
    required Color bgColor,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTypography.title.copyWith(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: const Color(0xFFA0A5B5),
              fontSize: 12.0,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCurriculumList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Curriculum',
          style: AppTypography.title.copyWith(
            color: Colors.white,
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
                color: const Color(0xFF181A20),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withOpacity(0.08), width: 1.2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
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
                                color: const Color(0xFF232730),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Color(0xFFC3F53C),
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
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (module.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      module.description,
                                      style: AppTypography.body.copyWith(
                                        color: const Color(0xFFA0A5B5),
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
                              color: Color(0xFFA0A5B5),
                              size: 16,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$completedMissions of $totalMissions Missions Completed',
                              style: AppTypography.body.copyWith(
                                color: const Color(0xFFA0A5B5),
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: AppTypography.code.copyWith(
                                color: progress == 1.0
                                    ? const Color(0xFF1DD1A1)
                                    : Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress == 1.0
                                  ? const Color(0xFF1DD1A1)
                                  : const Color(0xFFC3F53C),
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
