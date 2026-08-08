import 'package:flutter/material.dart';

import '../../../../core/progression/streak_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/curriculum.dart';
import '../../domain/models/module.dart';
import 'module_screen.dart';

/// Dashboard home screen featuring American Vintage Dark bento layout & live streak counter.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Vintage Retro Palette Constants
  static const Color _creamBeige = Color(0xFFE8D8C9);
  static const Color _cardDark = Color(0xFF1C1C1E);
  static const Color _retroOrange = Color(0xFFF3701E);
  static const Color _slateBlue = Color(0xFF4B607F);
  static const Color _textMuted = Color(0xFFA0A0A5);

  final CurriculumRepository _repository = CurriculumRepository();
  final StreakEngine _streakEngine = StreakEngine();

  Curriculum? _curriculum;
  StreakData? _streakData;
  bool _isLoading = true;
  String? _errorMessage;

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

  @override
  Widget build(BuildContext context) {
    final streakCount = _streakData?.currentStreak ?? 0;

    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _retroOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Python Forge',
              style: AppTypography.title.copyWith(
                color: _creamBeige,
                fontSize: 20.0,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Live Streak Counter Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: streakCount > 0
                    ? _retroOrange.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: streakCount > 0
                      ? _retroOrange.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: streakCount > 0 ? _retroOrange : _textMuted,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$streakCount',
                    style: AppTypography.title.copyWith(
                      color: streakCount > 0 ? _retroOrange : _creamBeige,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile Screen Navigation Button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _creamBeige,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF18181A),
                size: 18,
              ),
            ),
            onPressed: () {
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  )
                  .then((_) => _loadDashboardData());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_retroOrange),
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
      color: _retroOrange,
      backgroundColor: _cardDark,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          // Hero Resume Bento Card
          Container(
            padding: const EdgeInsets.all(22.0),
            decoration: BoxDecoration(
              color: _creamBeige,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstModule.title.toUpperCase(),
                  style: AppTypography.body.copyWith(
                    color: _slateBlue,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Continue Journey',
                  style: AppTypography.title.copyWith(
                    color: const Color(0xFF18181A),
                    fontSize: 22.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ModuleScreen(module: firstModule),
                          ),
                        )
                        .then((_) => _loadDashboardData());
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _retroOrange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Resume Learning',
                            style: AppTypography.title.copyWith(
                              color: Colors.white,
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),

          // Curriculum Header Label
          Text(
            'Curriculum Path',
            style: AppTypography.title.copyWith(
              color: _creamBeige,
              fontSize: 20.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Curriculum Module Bento List
          ...modules.map((module) => _buildModuleTile(module)),
        ],
      ),
    );
  }

  Widget _buildModuleTile(Module module) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (context) => ModuleScreen(module: module),
                ),
              )
              .then((_) => _loadDashboardData());
        },
        child: Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _creamBeige.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _slateBlue.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: _creamBeige,
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
                        color: _creamBeige,
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${module.missions.length} Missions • ${module.estimatedHours} hrs',
                      style: AppTypography.body.copyWith(
                        color: _textMuted,
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _creamBeige,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
