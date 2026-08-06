// FIX: Changed '../' to '../../'
import '../../domain/models/mission.dart';

/// Abstract repository contract for mission retrieval.
abstract class MissionRepository {
  List<Mission> getMissions();
  Mission? getMissionById(String id);
}

/// Local in-memory implementation of [MissionRepository].
class LocalMissionRepository implements MissionRepository {
  static const List<Mission> _missions = [
    Mission(
      id: 'mission_1',
      numberLabel: 'Mission 1',
      title: 'Hello, Python',
      description: 'Learn what Python is and print your first line of code.',
      objective: 'Print "Hello, World!"',
      validAnswers: ['print("Hello, World!")', "print('Hello, World!')"],
    ),
  ];

  @override
  List<Mission> getMissions() {
    return _missions;
  }

  @override
  Mission? getMissionById(String id) {
    try {
      return _missions.firstWhere((mission) => mission.id == id);
    } catch (_) {
      return null;
    }
  }
}
