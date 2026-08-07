import '../../../core/progression/progress_manager.dart';
import '../domain/models/learner_profile.dart';

class ProfileService {
  final ProgressManager progressManager;

  ProfileService({
    required this.progressManager,
  });

  Future<LearnerProfile> buildProfile() async {
    return LearnerProfile(
      currentLevel: await progressManager.currentLevel(),
      totalXp: await progressManager.totalXp(),
      completedMissionsCount: await progressManager.completedMissionCount(),
      achievementCount: 0,
      overallCompletionPercentage: await progressManager.completionPercentage(),
      currentModuleTitle: 'Python Foundations',
    );
  }
}
