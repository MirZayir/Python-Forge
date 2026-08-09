import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/curriculum.dart';
import '../../domain/models/mission.dart';

class CurriculumLoadException implements Exception {
  final String message;
  final Object? cause;

  const CurriculumLoadException(this.message, [this.cause]);

  @override
  String toString() => cause == null
      ? 'CurriculumLoadException: $message'
      : 'CurriculumLoadException: $message ($cause)';
}

/// Single source of truth for the bundled curriculum contract.
class CurriculumRepository {
  Curriculum? _cachedCurriculum;

  Future<Curriculum> getCurriculum() async {
    final cached = _cachedCurriculum;
    if (cached != null) return cached;

    try {
      final jsonString =
          await rootBundle.loadString('assets/curriculum/missions.json');
      final curriculum = Curriculum.fromJson(jsonDecode(jsonString));
      _validate(curriculum);
      _cachedCurriculum = curriculum;
      return curriculum;
    } on CurriculumLoadException {
      rethrow;
    } catch (error) {
      throw CurriculumLoadException(
        'Failed to load assets/curriculum/missions.json',
        error,
      );
    }
  }

  void clearCache() => _cachedCurriculum = null;

  void _validate(Curriculum curriculum) {
    if (curriculum.modules.isEmpty) {
      throw const CurriculumLoadException(
          'The curriculum contains no modules.');
    }

    final moduleIds = <String>{};
    final missionIds = <String>{};

    for (final module in curriculum.modules) {
      if (module.moduleId.trim().isEmpty) {
        throw const CurriculumLoadException('Every module needs a stable ID.');
      }
      if (!moduleIds.add(module.moduleId)) {
        throw CurriculumLoadException(
          'Duplicate module ID: ${module.moduleId}',
        );
      }
      if (module.missions.isEmpty) {
        throw CurriculumLoadException(
          'Module ${module.moduleId} contains no missions.',
        );
      }

      for (final mission in module.missions) {
        if (mission.id.trim().isEmpty) {
          throw CurriculumLoadException(
            'Module ${module.moduleId} contains a mission without an ID.',
          );
        }
        if (!missionIds.add(mission.id)) {
          throw CurriculumLoadException('Duplicate mission ID: ${mission.id}');
        }
        if (mission.validAnswers.isEmpty) {
          throw CurriculumLoadException(
            'Mission ${mission.id} contains no valid answer contract.',
          );
        }
        if (mission.type == MissionType.mcq &&
            (mission.mcqOptions == null || mission.mcqOptions!.isEmpty)) {
          throw CurriculumLoadException(
            'MCQ mission ${mission.id} contains no options.',
          );
        }
      }
    }
  }
}
