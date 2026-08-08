import '../../../../core/progression/achievement.dart';

/// Represents the aggregated progress and statistics of a learner.
class LearnerProfile {
  final int currentLevel;
  final int totalXp;
  final int completedMissionsCount;
  final int achievementCount;
  final double overallCompletionPercentage;
  final String currentModuleTitle;
  final List<Achievement> recentAchievements;

  const LearnerProfile({
    required this.currentLevel,
    required this.totalXp,
    required this.completedMissionsCount,
    required this.achievementCount,
    required this.overallCompletionPercentage,
    required this.currentModuleTitle,
    required this.recentAchievements,
  });
}
