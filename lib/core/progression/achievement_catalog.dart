import 'achievement.dart';

/// Metrics used to evaluate achievement requirements.
class AchievementMetrics {
  final int completedMissionCount;
  final int totalXp;
  final int currentStreak;

  const AchievementMetrics({
    this.completedMissionCount = 0,
    this.totalXp = 0,
    this.currentStreak = 0,
  });
}

/// A single achievement definition with its unlock requirement.
class AchievementDefinition {
  final Achievement achievement;
  final bool Function(AchievementMetrics metrics) isEarned;

  const AchievementDefinition({
    required this.achievement,
    required this.isEarned,
  });

  String get id => achievement.id;
}

/// The single achievement catalog shared by the engine and the UI.
///
/// Previously the engine and the achievements screen declared different IDs,
/// so unlocked achievements could never be displayed.
abstract class AchievementCatalog {
  static final List<AchievementDefinition> definitions = [
    AchievementDefinition(
      achievement: const Achievement(
        id: 'first_mission',
        title: 'Spark Ignited',
        description: 'Complete your very first mission in Python Forge.',
      ),
      isEarned: (metrics) => metrics.completedMissionCount >= 1,
    ),
    AchievementDefinition(
      achievement: const Achievement(
        id: 'explorer',
        title: 'Explorer',
        description: 'Complete 5 missions.',
      ),
      isEarned: (metrics) => metrics.completedMissionCount >= 5,
    ),
    AchievementDefinition(
      achievement: const Achievement(
        id: 'scholar',
        title: 'Scholar',
        description: 'Complete 10 missions.',
      ),
      isEarned: (metrics) => metrics.completedMissionCount >= 10,
    ),
    AchievementDefinition(
      achievement: const Achievement(
        id: 'streak_3',
        title: 'On Fire',
        description: 'Maintain a 3-day active learning streak.',
      ),
      isEarned: (metrics) => metrics.currentStreak >= 3,
    ),
    AchievementDefinition(
      achievement: const Achievement(
        id: 'xp_500',
        title: 'XP Collector',
        description: 'Accumulate 500 total experience points.',
      ),
      isEarned: (metrics) => metrics.totalXp >= 500,
    ),
  ];

  static List<Achievement> get all =>
      definitions.map((definition) => definition.achievement).toList();

  static Achievement? byId(String id) {
    for (final definition in definitions) {
      if (definition.id == id) return definition.achievement;
    }
    return null;
  }
}
