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
      final jsonString = await rootBundle.loadString(
        'assets/curriculum/missions.json',
        cache: false,
      );
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

  /// Validates an already parsed curriculum for authoring and contract tests.
  /// Runtime loading uses the same method before caching the asset.
  void validateCurriculum(Curriculum curriculum) => _validate(curriculum);

  void _validate(Curriculum curriculum) {
    if (curriculum.id.trim().isEmpty || curriculum.version.trim().isEmpty) {
      throw const CurriculumLoadException(
        'The curriculum needs a stable ID and version.',
      );
    }
    if (curriculum.title.trim().isEmpty ||
        curriculum.description.trim().isEmpty) {
      throw const CurriculumLoadException(
        'The curriculum needs a title and description.',
      );
    }
    if (curriculum.modules.isEmpty) {
      throw const CurriculumLoadException(
        'The curriculum contains no modules.',
      );
    }

    final moduleIds = <String>{};
    final moduleOrders = <int>{};
    final missionIds = <String>{};
    final prerequisiteLinks = <({String missionId, String prerequisiteId})>[];

    for (final module in curriculum.modules) {
      final moduleId = module.moduleId.trim();
      if (moduleId.isEmpty) {
        throw const CurriculumLoadException('Every module needs a stable ID.');
      }
      if (!moduleIds.add(moduleId)) {
        throw CurriculumLoadException('Duplicate module ID: $moduleId');
      }
      if (module.order <= 0 || !moduleOrders.add(module.order)) {
        throw CurriculumLoadException(
          'Module $moduleId must have a unique positive order.',
        );
      }
      if (module.title.trim().isEmpty || module.description.trim().isEmpty) {
        throw CurriculumLoadException(
          'Module $moduleId needs a title and description.',
        );
      }
      if (!module.estimatedHours.isFinite || module.estimatedHours < 0) {
        throw CurriculumLoadException(
          'Module $moduleId has an invalid estimated hour value.',
        );
      }
      if (module.missions.isEmpty) {
        throw CurriculumLoadException('Module $moduleId contains no missions.');
      }

      for (final mission in module.missions) {
        final missionId = mission.id.trim();
        if (missionId.isEmpty) {
          throw CurriculumLoadException(
            'Module $moduleId contains a mission without an ID.',
          );
        }
        if (!missionIds.add(missionId)) {
          throw CurriculumLoadException('Duplicate mission ID: $missionId');
        }
        if (mission.title.trim().isEmpty ||
            mission.description.trim().isEmpty ||
            mission.objective.trim().isEmpty) {
          throw CurriculumLoadException(
            'Mission $missionId needs a title, description, and objective.',
          );
        }

        final validationType =
            mission.validationRules.type.trim().toLowerCase();
        if (validationType != 'exact_match') {
          throw CurriculumLoadException(
            'Mission $missionId uses unsupported validation type: $validationType',
          );
        }
        final answers = mission.validAnswers
            .map((answer) => answer.trim())
            .where((answer) => answer.isNotEmpty)
            .toList(growable: false);
        if (answers.isEmpty || answers.length != answers.toSet().length) {
          throw CurriculumLoadException(
            'Mission $missionId contains an empty or duplicate answer contract.',
          );
        }

        final options = mission.mcqOptions
            ?.map((option) => option.trim())
            .where((option) => option.isNotEmpty)
            .toList(growable: false);
        if (mission.type == MissionType.mcq) {
          if (options == null ||
              options.isEmpty ||
              options.length != options.toSet().length) {
            throw CurriculumLoadException(
              'MCQ mission $missionId must contain unique non-empty options.',
            );
          }
          final normalizedOptions = options.map(_normalize).toSet();
          if (answers.any(
              (answer) => !normalizedOptions.contains(_normalize(answer)))) {
            throw CurriculumLoadException(
              'MCQ mission $missionId has an answer missing from its options.',
            );
          }
        } else if (options != null && options.isNotEmpty) {
          throw CurriculumLoadException(
            'Only MCQ mission $missionId may define answer options.',
          );
        }

        final prerequisites = mission.prerequisites
            .map((prerequisite) => prerequisite.trim())
            .where((prerequisite) => prerequisite.isNotEmpty)
            .toList(growable: false);
        if (prerequisites.length != mission.prerequisites.length ||
            prerequisites.length != prerequisites.toSet().length ||
            prerequisites.contains(missionId)) {
          throw CurriculumLoadException(
            'Mission $missionId contains invalid prerequisite references.',
          );
        }
        for (final prerequisite in prerequisites) {
          prerequisiteLinks.add(
            (missionId: missionId, prerequisiteId: prerequisite),
          );
        }
      }
    }

    for (final link in prerequisiteLinks) {
      if (!missionIds.contains(link.prerequisiteId)) {
        throw CurriculumLoadException(
          'Mission ${link.missionId} references unknown prerequisite ${link.prerequisiteId}.',
        );
      }
    }
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
