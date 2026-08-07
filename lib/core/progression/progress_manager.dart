import 'package:shared_preferences/shared_preferences.dart';

/// Centralized manager for tracking and persisting learner progress.
class ProgressManager {
  /// Marks a mission as completed and unlocks the next mission.
  Future<void> completeMission(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${missionId}_completed', true);

    // Auto-unlock the next mission by extracting the sequence number (e.g., 'mission_01' -> 1)
    final match = RegExp(r'\d+').firstMatch(missionId);
    if (match != null) {
      final currentMissionNum = int.parse(match.group(0)!);
      final maxUnlocked = prefs.getInt('max_unlocked_mission') ?? 1;

      if (currentMissionNum >= maxUnlocked) {
        await prefs.setInt('max_unlocked_mission', currentMissionNum + 1);
      }
    }
  }

  /// Checks if a specific mission has been completed.
  Future<bool> isMissionCompleted(String missionId) async {
    final prefs = await SharedPreferences.getInstance();

    // Check the standardized ID-based key
    final isCompletedById = prefs.getBool('${missionId}_completed') ?? false;

    // Fallback for legacy number-based keys to preserve existing local progression
    final match = RegExp(r'\d+').firstMatch(missionId);
    bool isCompletedByLegacy = false;
    if (match != null) {
      final currentMissionNum = int.parse(match.group(0)!);
      isCompletedByLegacy =
          prefs.getBool('mission_${currentMissionNum}_completed') ?? false;
    }

    return isCompletedById || isCompletedByLegacy;
  }

  /// Returns the total number of unique missions completed across all modules.
  Future<int> completedMissionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    return keys
        .where((k) => k.endsWith('_completed') && prefs.getBool(k) == true)
        .length;
  }

  /// Returns the user's total accumulated XP.
  Future<int> totalXp() async {
    // Total XP calculation will be fully implemented in a future ticket
    return 0;
  }

  /// Returns the user's current level.
  Future<int> currentLevel() async {
    // Level progression will be fully implemented in a future ticket
    return 1;
  }

  /// Returns the overall curriculum completion percentage.
  Future<double> completionPercentage() async {
    // Global completion calculation will be fully implemented in a future ticket
    return 0.0;
  }
}
