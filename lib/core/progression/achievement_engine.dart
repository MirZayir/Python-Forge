import 'package:shared_preferences/shared_preferences.dart';

import 'achievement.dart';
import 'progress_manager.dart';

/// Evaluates learner progress and unlocks achievements accordingly.
class AchievementEngine {
  static const List<Achievement> _achievements = [
    Achievement(
      id: 'first_program',
      title: 'First Program',
      description: 'Write and successfully run your first Python program.',
    ),
    Achievement(
      id: 'explorer',
      title: 'Explorer',
      description: 'Complete 2 missions.',
    ),
    Achievement(
      id: 'apprentice',
      title: 'Apprentice',
      description: 'Complete 5 missions.',
    ),
    Achievement(
      id: 'scholar',
      title: 'Scholar',
      description: 'Complete 10 missions.',
    ),
    Achievement(
      id: 'persistent',
      title: 'Persistent',
      description: 'Maintain a 3-day learning streak.', // Placeholder logic
    ),
  ];

  final ProgressManager _progressManager = ProgressManager();

  /// Evaluates all locked achievements against current progress metrics.
  /// Returns a list of newly unlocked achievements during this execution.
  Future<List<Achievement>> evaluateAndUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = prefs.getStringList('unlocked_achievements') ?? [];

    final newlyUnlocked = <Achievement>[];
    final completedCount = await _progressManager.completedMissionCount();

    for (final achievement in _achievements) {
      // Skip if already unlocked
      if (unlockedIds.contains(achievement.id)) {
        continue;
      }

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'first_program':
          shouldUnlock = completedCount >= 1;
          break;
        case 'explorer':
          shouldUnlock = completedCount >= 2;
          break;
        case 'apprentice':
          shouldUnlock = completedCount >= 5;
          break;
        case 'scholar':
          shouldUnlock = completedCount >= 10;
          break;
        case 'persistent':
          // Placeholder for future streak implementation
          shouldUnlock = false;
          break;
      }

      if (shouldUnlock) {
        unlockedIds.add(achievement.id);
        newlyUnlocked.add(achievement);
      }
    }

    // Persist changes only if new achievements were unlocked
    if (newlyUnlocked.isNotEmpty) {
      await prefs.setStringList('unlocked_achievements', unlockedIds);
    }

    return newlyUnlocked;
  }
}
