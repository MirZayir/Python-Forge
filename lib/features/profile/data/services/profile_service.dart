import '../../../../core/progression/achievement_engine.dart';
import '../../../../core/progression/learning_progress.dart';
import '../../domain/models/learner_profile.dart';

/// Builds the learner profile from the single derived progress source.
class ProfileService {
  final LearningProgressService _progressService;
  final AchievementEngine _achievementEngine;

  ProfileService({
    LearningProgressService? progressService,
    AchievementEngine? achievementEngine,
  })  : _progressService = progressService ?? LearningProgressService(),
        _achievementEngine = achievementEngine ?? AchievementEngine();

  Future<LearnerProfile> getProfile() async {
    final progress = await _progressService.load();
    final unlockedAchievements =
        await _achievementEngine.getUnlockedAchievements();

    final currentModuleTitle = progress.isFullyCompleted
        ? 'All modules completed'
        : (progress.nextModule?.title ??
            (progress.modules.isEmpty
                ? 'No modules'
                : progress.modules.first.title));

    return LearnerProfile(
      currentLevel: progress.level,
      totalXp: progress.totalXp,
      completedMissionsCount: progress.completedMissionCount,
      achievementCount: unlockedAchievements.length,
      overallCompletionPercentage: progress.completionPercent,
      currentModuleTitle: currentModuleTitle,
      recentAchievements: unlockedAchievements.reversed.take(3).toList(),
    );
  }
}
