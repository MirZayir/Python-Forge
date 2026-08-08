import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mission_repository.dart';
import '../../domain/models/mission.dart';

/// Provides the instance of [MissionRepository].
final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  return LocalMissionRepository();
});

/// A Notifier that safely bridges the async JSON loading with the synchronous UI.
class MissionsNotifier extends Notifier<List<Mission>> {
  @override
  List<Mission> build() {
    _loadMissions();
    return []; // Return empty list immediately so HomeScreen doesn't need to change
  }

  Future<void> _loadMissions() async {
    final repository = ref.read(missionRepositoryProvider);
    final missions = await repository.getMissions();
    state = missions; // Triggers UI rebuild in HomeScreen once loaded
  }
}

/// Provides the reactive list of available missions.
final missionsProvider = NotifierProvider<MissionsNotifier, List<Mission>>(
  MissionsNotifier.new,
);
