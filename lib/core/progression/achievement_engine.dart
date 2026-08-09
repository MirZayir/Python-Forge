import 'package:shared_preferences/shared_preferences.dart';

import 'achievement.dart';
import 'achievement_catalog.dart';

/// Evaluates learner metrics and unlocks achievements from the shared catalog.
class AchievementEngine {
  static const String unlockedKey = 'unlocked_achievements';

  Future<Set<String>> unlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(unlockedKey) ?? const <String>[]).toSet();
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final ids = await unlockedIds();
    return AchievementCatalog.definitions
        .where((definition) => ids.contains(definition.id))
        .map((definition) => definition.achievement)
        .toList();
  }

  /// Unlocks any newly earned achievements and returns only the new ones.
  Future<List<Achievement>> evaluateAndUnlock(
    AchievementMetrics metrics,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked =
        (prefs.getStringList(unlockedKey) ?? const <String>[]).toSet();

    final newlyUnlocked = <Achievement>[];
    for (final definition in AchievementCatalog.definitions) {
      if (unlocked.contains(definition.id)) continue;
      if (!definition.isEarned(metrics)) continue;
      unlocked.add(definition.id);
      newlyUnlocked.add(definition.achievement);
    }

    if (newlyUnlocked.isNotEmpty) {
      await prefs.setStringList(unlockedKey, unlocked.toList());
    }
    return newlyUnlocked;
  }
}
