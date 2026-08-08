import '../../features/curriculum/domain/models/mission.dart';

/// Centralized manager for calculating experience point (XP) rewards.
class XpManager {
  /// Calculates the XP reward for completing the given [mission] based on its difficulty.
  static int rewardFor(Mission mission) {
    switch (mission.difficulty.toLowerCase()) {
      case 'beginner':
        return 25;
      case 'easy':
        return 50;
      case 'medium':
        return 100;
      case 'hard':
        return 200;
      case 'expert':
        return 400;
      default:
        return 25;
    }
  }
}
