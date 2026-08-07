import 'package:flutter/material.dart';
import '../../../../core/progression/progress_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/learner_profile.dart';
import '../../data/profile_service.dart';

/// Displays the learner's progression dashboard, stats, and achievements.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService(
    progressManager: ProgressManager(),
  );

  LearnerProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.buildProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Learner Profile',
          style: AppTypography.title.copyWith(color: Colors.white),
        ),
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

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: [
        // Level & XP Banner
        ForgeCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${p.currentLevel}',
                    style: AppTypography.title.copyWith(
                      color: AppColors.logicCyan,
                      fontSize: 28.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.micro),
                  Text(
                    '${p.totalXp} Total XP',
                    style: AppTypography.body
                        .copyWith(color: AppColors.syntaxGrey),
                  ),
                ],
              ),
              const Icon(
                Icons.military_tech,
                color: AppColors.forgeEmber,
                size: 56.0,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),

        // Statistics Grid
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Missions',
                value: '${p.completedMissionsCount}',
                icon: Icons.task_alt,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: _StatCard(
                label: 'Achievements',
                value: '${p.achievementCount}',
                icon: Icons.emoji_events,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),

        // Current Progress
        ForgeCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Focus',
                style: AppTypography.body.copyWith(
                  color: AppColors.syntaxGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                p.currentModuleTitle,
                style: AppTypography.title.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.medium),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: LinearProgressIndicator(
                  value: p.overallCompletionPercentage,
                  backgroundColor: AppColors.obsidian,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.temperGreen),
                  minHeight: 8.0,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                '${(p.overallCompletionPercentage * 100).toStringAsFixed(0)}% Overall Completion',
                style: AppTypography.body.copyWith(
                  color: AppColors.syntaxGrey,
                  fontSize: 12.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ForgeCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.logicCyan, size: 28.0),
          const SizedBox(height: AppSpacing.small),
          Text(
            value,
            style: AppTypography.title.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.micro),
          Text(
            label,
            style: AppTypography.body.copyWith(color: AppColors.syntaxGrey),
          ),
        ],
      ),
    );
  }
}
