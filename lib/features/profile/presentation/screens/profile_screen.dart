import 'package:flutter/material.dart';

import '../../../../core/progression/streak_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../data/services/profile_service.dart';
import '../../domain/models/learner_profile.dart';

/// Learner profile dashboard synced with live StreakEngine and Progress statistics.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Vintage Retro Palette Constants
  static const Color _cardDark = Color(0xFF1C1C1E);
  static const Color _creamBeige = Color(0xFFE8D8C9);
  static const Color _slateBlue = Color(0xFF4B607F);
  static const Color _retroOrange = Color(0xFFF3701E);
  static const Color _textMuted = Color(0xFFA0A0A5);

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _creamBeige, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Learner Profile',
          style: AppTypography.title.copyWith(
            color: _creamBeige,
            fontSize: 20.0,
            fontWeight: FontWeight.w800,
          ),
        ),
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
            'Failed to load profile: $_errorMessage',
            style: AppTypography.body.copyWith(color: AppColors.slagRed),
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
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: _slateBlue,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _retroOrange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'LEVEL ${p.currentLevel}',
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${p.totalXp} XP',
                    style: AppTypography.title.copyWith(
                      color: Colors.white,
                      fontSize: 28.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Experience Points',
                    style: AppTypography.body.copyWith(
                      color: _creamBeige.withValues(alpha: 0.8),
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: _creamBeige,
                  size: 44.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),

        // Bento Statistics Grid (Missions, Streak, Achievements)
        Row(
          children: [
            Expanded(
              child: _buildBentoStatCard(
                label: 'Daily Streak',
                value: '$streak Days',
                icon: Icons.local_fire_department_rounded,
                accentColor: _retroOrange,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: _buildBentoStatCard(
                label: 'Missions Done',
                value: '${p.completedMissionsCount}',
                icon: Icons.check_circle_rounded,
                accentColor: _creamBeige,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),

        // Current Focus Bento Box
        Container(
          padding: const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: _cardDark,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: _creamBeige.withValues(alpha: 0.12), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CURRENT FOCUS',
                    style: AppTypography.body.copyWith(
                      color: _textMuted,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '${(p.overallCompletionPercentage * 100).toInt()}% Complete',
                    style: AppTypography.code.copyWith(
                      color: _retroOrange,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                p.currentModuleTitle,
                style: AppTypography.title.copyWith(
                  color: _creamBeige,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: p.overallCompletionPercentage,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(_retroOrange),
                  minHeight: 10.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),

        // Recent Achievements List
        if (p.recentAchievements.isNotEmpty) ...[
          Text(
            'Recent Achievements',
            style: AppTypography.title.copyWith(
              color: _creamBeige,
              fontSize: 20.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          ...p.recentAchievements.map(
            (achievement) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: _cardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: _retroOrange.withValues(alpha: 0.25), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _retroOrange.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: _retroOrange,
                        size: 26.0,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: AppTypography.title.copyWith(
                              color: _creamBeige,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.description,
                            style: AppTypography.body.copyWith(
                              color: _textMuted,
                              fontSize: 13.0,
                              height: 1.3,
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
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: AppTypography.title.copyWith(
              color: _creamBeige,
              fontSize: 22.0,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: _textMuted,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
