import 'package:flutter/material.dart';

import '../../../../core/progression/achievement.dart';
import '../../../../core/progression/achievement_catalog.dart';
import '../../../../core/progression/achievement_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/forge_scaffold.dart';

/// Bento grid displaying unlocked and locked achievement badges in Neubrutalism style.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementEngine _achievementEngine = AchievementEngine();

  List<Achievement> _allAchievements = [];
  Set<String> _unlockedIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievementsData();
  }

  Future<void> _loadAchievementsData() async {
    final unlockedIds = await _achievementEngine.unlockedIds();

    if (mounted) {
      setState(() {
        _allAchievements = AchievementCatalog.all;
        _unlockedIds = unlockedIds;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _unlockedIds.length;
    final totalCount = _allAchievements.length;

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
          'Achievements',
          style: TextStyle(
            color: AppColors.borderBlack,
            fontSize: 20.0,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Container(
        color: AppColors.bgCream,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.borderBlack),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.large),
                physics: const BouncingScrollPhysics(),
                children: [
                  // Trophy Summary Header Card
                  Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: AppColors.neuYellow,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.shadowBlack,
                          offset: Offset(4, 4),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.borderBlack, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppColors.borderBlack,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TROPHY COLLECTION',
                                style: TextStyle(
                                  color: AppColors.borderBlack,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$unlockedCount of $totalCount Unlocked',
                                style: const TextStyle(
                                  color: AppColors.borderBlack,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),

                  ..._allAchievements.map((achievement) {
                    final isUnlocked = _unlockedIds.contains(achievement.id);
                    return _buildAchievementCard(achievement, isUnlocked);
                  }),
                ],
              ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement, bool isUnlocked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.cardWhite : AppColors.bgCream,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderBlack, width: 2.5),
          boxShadow: isUnlocked
              ? const [
                  BoxShadow(
                    color: AppColors.shadowBlack,
                    offset: Offset(3, 3),
                    blurRadius: 0,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUnlocked ? AppColors.neuYellow : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderBlack, width: 2.0),
              ),
              child: Icon(
                isUnlocked
                    ? Icons.emoji_events_rounded
                    : Icons.lock_outline_rounded,
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
                    style: TextStyle(
                      color: isUnlocked
                          ? AppColors.borderBlack
                          : Colors.grey.shade600,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: isUnlocked
                          ? const Color(0xFF555555)
                          : Colors.grey.shade500,
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
    );
  }
}
