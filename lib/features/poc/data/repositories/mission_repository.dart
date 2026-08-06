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
        'assets/curriculum/mission_001.json',
      );

      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      final mission = Mission(
        id: jsonMap['id'] as String,
        numberLabel: jsonMap['numberLabel'] as String,
        title: jsonMap['title'] as String,
        description: jsonMap['description'] as String,
        objective: jsonMap['objective'] as String,
        validAnswers: List<String>.from(jsonMap['validAnswers'] as List),
      );

      _cachedMissions = [mission];
      return _cachedMissions!;
    } catch (e) {
      // In a production app, log this using Logger.e()
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
