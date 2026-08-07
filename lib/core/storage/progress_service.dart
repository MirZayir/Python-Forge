import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _completedMissionsKey = 'completed_missions';

  Future<List<String>> getCompletedMissions() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getStringList(_completedMissionsKey) ?? [];
  }

  Future<void> completeMission(String missionId) async {
    final prefs = await SharedPreferences.getInstance();

    final completed = prefs.getStringList(_completedMissionsKey) ?? [];

    if (!completed.contains(missionId)) {
      completed.add(missionId);
      await prefs.setStringList(_completedMissionsKey, completed);
    }
  }

  Future<bool> isMissionCompleted(String missionId) async {
    final completed = await getCompletedMissions();
    return completed.contains(missionId);
  }
}
