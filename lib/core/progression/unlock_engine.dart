import '../../features/curriculum/domain/models/mission.dart';
import 'learning_progress.dart';

/// Evaluates mission availability using the canonical progression rules.
class UnlockEngine {
  final LearningProgressService _progressService;

  UnlockEngine({LearningProgressService? progressService})
      : _progressService = progressService ?? LearningProgressService();

  Future<bool> isUnlocked(Mission mission) async {
    final progress = await _progressService.load();
    return progress.isMissionUnlocked(mission.id);
  }

  Future<List<Mission>> unlockedMissions(List<Mission> missions) async {
    final progress = await _progressService.load();
    return missions
        .where((mission) => progress.isMissionUnlocked(mission.id))
        .toList();
  }
}
