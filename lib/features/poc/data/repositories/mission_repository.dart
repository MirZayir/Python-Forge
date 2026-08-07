import 'dart:convert';
import 'package:flutter/services.dart';

import '../../domain/models/mission.dart';

/// Abstract repository contract for mission retrieval.
abstract class MissionRepository {
  Future<List<Mission>> getMissions();
  Future<Mission?> getMissionById(String id);
}

/// Local JSON implementation of [MissionRepository].
class LocalMissionRepository implements MissionRepository {
  List<Mission>? _cachedMissions;

  @override
  Future<List<Mission>> getMissions() async {
    // Return cached data if already loaded to avoid redundant file I/O
    if (_cachedMissions != null) return _cachedMissions!;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/curriculum/missions.json',
      );

      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;

      _cachedMissions = jsonList.asMap().entries.map((entry) {
        final map = entry.value as Map<String, dynamic>;

        return Mission.fromJson(
          map,
          numberLabel: 'Mission ${entry.key + 1}',
        );
      }).toList();

      return _cachedMissions!;
    } catch (e) {
      // [FIXME]: Replace silent catch with robust typed exception handling and Logger.e()
      return [];
    }
  }

  @override
  Future<Mission?> getMissionById(String id) async {
    final missions = await getMissions();
    try {
      return missions.firstWhere((mission) => mission.id == id);
    } catch (_) {
      return null;
    }
  }
}
