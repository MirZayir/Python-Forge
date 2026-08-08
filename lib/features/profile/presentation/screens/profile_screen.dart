import 'package:flutter/material.dart';

import '../../../../core/progression/streak_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../data/services/profile_service.dart';
import '../../domain/models/learner_profile.dart';
import 'achievements_screen.dart';

/// Learner profile dashboard transformed into Neubrutalism style.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final StreakEngine _streakEngine = StreakEngine();

  LearnerProfile? _profile;
  StreakData? _streakData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profile = await _profileService.getProfile();
      final streak = await _streakEngine.getStreakData();

      if (mounted) {
        setState(() {
          _profile = profile;
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
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
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
              Icons.arrow_back_rounded,
              color: AppColors.borderBlack,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Learner Profile',
          style: TextStyle(
            color: AppColors.borderBlack,
            fontSize: 20.0,
            fontWeight: FontWeight.w900,
          ),
        ),
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
            'Failed to load profile: $_errorMessage',
            style: const TextStyle(
                color: AppColors.slagRed, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_profile == null) {
      return const SizedBox.shrink();
    }

    final p = _profile!;
    final streak = _streakData?.currentStreak ?? 0;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      physics: const BouncingScrollPhysics(),
      children: [
        // Level & XP Hero Bento Card
        Container(
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: AppColors.neuPurple,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderBlack, width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowBlack,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.neuYellow,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2.0),
                    ),
                    child: Text(
                      'LEVEL ${p.currentLevel}',
                      style: const TextStyle(
                        color: AppColors.borderBlack,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${p.totalXp} XP',
                    style: const TextStyle(
                      color: AppColors.borderBlack,
                      fontSize: 28.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Total Experience Points',
                    style: TextStyle(
                      color: AppColors.borderBlack,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderBlack, width: 2.5),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: AppColors.borderBlack,
                  size: 38.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bento Statistics Grid
        Row(
          children: [
            Expanded(
              child: _buildBentoStatCard(
                label: 'Daily Streak',
                value: '$streak Days',
                icon: Icons.local_fire_department_rounded,
                accentColor: AppColors.neuYellow,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildBentoStatCard(
                label: 'Missions Done',
                value: '${p.completedMissionsCount}',
                icon: Icons.check_circle_rounded,
                accentColor: AppColors.neuGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Current Focus Bento Box
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
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
                  const Text(
                    'CURRENT FOCUS',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${(p.overallCompletionPercentage * 100).toInt()}% Complete',
                    style: const TextStyle(
                      color: AppColors.borderBlack,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                p.currentModuleTitle,
                style: const TextStyle(
                  color: AppColors.borderBlack,
                  fontSize: 18.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
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
                    value: p.overallCompletionPercentage,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.neuYellow),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recent Achievements Header
        if (p.recentAchievements.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Achievements',
                style: TextStyle(
                  color: AppColors.borderBlack,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AchievementsScreen(),
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.neuYellow,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.0),
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.borderBlack,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...p.recentAchievements.map(
            (achievement) => Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderBlack, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.shadowBlack,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.neuYellow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.borderBlack, width: 2.0),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.borderBlack,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: const TextStyle(
                              color: AppColors.borderBlack,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            achievement.description,
                            style: const TextStyle(
                              color: Color(0xFF555555),
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBentoStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBlack, width: 2.0),
            ),
            child: Icon(icon, color: AppColors.borderBlack, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.borderBlack,
              fontSize: 20.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
