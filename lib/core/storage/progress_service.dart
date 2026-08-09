import '../progression/progress_manager.dart';

/// Compatibility facade over the canonical ProgressManager store.
class ProgressService {
  final ProgressManager _progressManager;

  ProgressService({ProgressManager? progressManager})
      : _progressManager = progressManager ?? ProgressManager();

  Future<List<String>> getCompletedMissions() =>
      _progressManager.getCompletedMissionIds();

  Future<void> completeMission(String missionId) =>
      _progressManager.completeMission(missionId);

  Future<bool> isMissionCompleted(String missionId) =>
      _progressManager.isMissionCompleted(missionId);
}
