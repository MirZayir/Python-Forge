import '../../../../core/progression/achievement_engine.dart';
import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/xp_manager.dart';
import '../../../poc/data/repositories/curriculum_repository.dart';
import '../models/learner_profile.dart';

class ProfileService {
  final ProgressManager progressManager = ProgressManager();
  final AchievementEngine _achievementEngine = AchievementEngine();
  final CurriculumRepository _curriculumRepository = CurriculumRepository();

  ProfileService();

  Future<LearnerProfile> buildProfile() async {
    return getProfile();
  }

  Future<LearnerProfile> getProfile() async {
    final curriculum = await _curriculumRepository.getCurriculum();
    final unlockedAchievements =
        await _achievementEngine.getUnlockedAchievements();

    int totalXp = 0;
    int completedMissions = 0;
    int totalMissions = 0;
    String currentModuleTitle = "All Modules Completed";
    bool foundCurrentModule = false;

    for (final module in curriculum.modules) {
      bool moduleCompleted = true;
      totalMissions += module.missions.length;

      for (final mission in module.missions) {
        final isCompleted =
            await progressManager.isMissionCompleted(mission.id);
        if (isCompleted) {
          completedMissions++;
          totalXp += XpManager.rewardFor(mission);
        } else {
          moduleCompleted = false;
        }
      }

      if (!moduleCompleted && !foundCurrentModule) {
        currentModuleTitle = module.title;
        foundCurrentModule = true;
      }
    }

    final completionPercentage =
        totalMissions == 0 ? 0.0 : (completedMissions / totalMissions);
    final currentLevel = (totalXp / 100).floor() + 1;

    return LearnerProfile(
      currentLevel: currentLevel,
      totalXp: totalXp,
      completedMissionsCount: completedMissions,
      achievementCount: unlockedAchievements.length,
      overallCompletionPercentage: completionPercentage,
      currentModuleTitle: currentModuleTitle,
      recentAchievements: unlockedAchievements.reversed.take(3).toList(),
    );
  }
}
