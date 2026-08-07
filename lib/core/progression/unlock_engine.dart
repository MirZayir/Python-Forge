import '../../features/poc/domain/models/mission.dart';
import 'progress_manager.dart';

/// Central engine evaluating mission prerequisites to determine unlock states.
class UnlockEngine {
  final ProgressManager _progressManager = ProgressManager();

  /// Determines if a specific [mission] is unlocked by checking if all its prerequisites are completed.
  Future<bool> isUnlocked(Mission mission) async {
    // Missions with no prerequisites are always unlocked by default.
    if (mission.prerequisites.isEmpty) {
      return true;
    }

    // Verify all prerequisites are met
    for (final prereqId in mission.prerequisites) {
      final isCompleted = await _progressManager.isMissionCompleted(prereqId);
      if (!isCompleted) {
        return false;
      }
    }

    return true;
  }

  /// Returns a filtered list of only the unlocked missions from the provided [missions].
  Future<List<Mission>> unlockedMissions(List<Mission> missions) async {
    final List<Mission> unlocked = [];
    for (final mission in missions) {
      if (await isUnlocked(mission)) {
        unlocked.add(mission);
      }
    }
    return unlocked;
  }
}
