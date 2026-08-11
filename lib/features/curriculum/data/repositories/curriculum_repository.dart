import 'dart:convert';

import 'package:crypto/crypto.dart';
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
  static const _curriculumAssetPath = 'assets/curriculum/missions.json';
  static const _curriculumManifestAssetPath = 'assets/curriculum/manifest.json';

  Curriculum? _cachedCurriculum;

  Future<Curriculum> getCurriculum() async {
    final cached = _cachedCurriculum;
    if (cached != null) return cached;

    try {
      final jsonString = await rootBundle.loadString(
        _curriculumAssetPath,
        cache: false,
      );
      final manifestString = await rootBundle.loadString(
        _curriculumManifestAssetPath,
        cache: false,
      );
      final curriculumSource = jsonDecode(jsonString);
      final manifestSource = jsonDecode(manifestString);
      final curriculum = Curriculum.fromJson(curriculumSource);
      _validateManifest(manifestSource, curriculumSource, curriculum);
      _validate(curriculum);
      _cachedCurriculum = curriculum;
      return curriculum;
    } on CurriculumLoadException {
      rethrow;
    } catch (error) {
      throw CurriculumLoadException(
        'Failed to load bundled curriculum assets.',
        error,
      );
    }
  }

  void clearCache() => _cachedCurriculum = null;

  /// Validates an already parsed curriculum for authoring and contract tests.
  /// Runtime loading uses the same method before caching the asset.
  void validateCurriculum(Curriculum curriculum) => _validate(curriculum);

  static void _validateManifest(
    Object? source,
    Object? curriculumSource,
    Curriculum curriculum,
  ) {
    if (source is! Map<String, dynamic>) {
      throw const CurriculumLoadException(
        'The curriculum manifest must be a JSON object.',
      );
    }

    final manifestVersion = source['manifest_version'];
    final curriculumId = source['curriculum_id'];
    final curriculumVersion = source['curriculum_version'];
    final contentPath = source['content_path'];
    final contentSha256 = source['content_sha256'];
    final hashAlgorithm = source['hash_algorithm'];
    final canonicalization = source['canonicalization'];
    final migrationPolicy = source['migration_policy'];

    if (manifestVersion != 1 ||
        curriculumId != curriculum.id ||
        curriculumVersion != curriculum.version ||
        contentPath != _curriculumAssetPath ||
        hashAlgorithm != 'sha256' ||
        canonicalization != 'json-v1-sort-keys-no-whitespace' ||
        !_isSha256(contentSha256)) {
      throw const CurriculumLoadException(
        'The curriculum manifest has an invalid schema or identity.',
      );
    }

    if (migrationPolicy is! Map<String, dynamic> ||
        migrationPolicy['stable_id_field'] != 'mission.id' ||
        migrationPolicy['unknown_completion_ids'] != 'discard' ||
        migrationPolicy['content_change'] != 'require_manifest_update') {
      throw const CurriculumLoadException(
        'The curriculum manifest has an unsupported migration policy.',
      );
    }

    final actualHash = _canonicalJsonHash(curriculumSource);
    if (actualHash != contentSha256) {
      throw CurriculumLoadException(
        'The curriculum content hash does not match its manifest: '
        'expected $contentSha256, got $actualHash.',
      );
    }
  }

  static String _canonicalJsonHash(Object? source) {
    final canonicalJson = _canonicalJson(source);
    return sha256.convert(utf8.encode(canonicalJson)).toString();
  }

  static String _canonicalJson(Object? source) {
    if (source is Map) {
      final keys = source.keys.cast<String>().toList()..sort();
      return '{${keys.map((key) {
        return '${jsonEncode(key)}:${_canonicalJson(source[key])}';
      }).join(',')}}';
    }
    if (source is List) {
      return '[${source.map((value) => _canonicalJson(value)).join(',')}]';
    }
    if (source == null || source is String || source is num || source is bool) {
      return jsonEncode(source);
    }
    throw const FormatException(
      'Curriculum content contains a value that cannot be canonicalized.',
    );
  }

  static bool _isSha256(Object? value) {
    return value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
  }

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
    final prerequisitesByMission = <String, List<String>>{};
    final prerequisiteLinks = <({String missionId, String prerequisiteId})>[];

    for (final module in curriculum.modules) {
      final moduleId = module.moduleId.trim();
      if (moduleId.isEmpty) {
        throw const CurriculumLoadException('Every module needs a stable ID.');
      }
      if (module.moduleId != moduleId) {
        throw CurriculumLoadException(
          'Module IDs must not contain surrounding whitespace: $moduleId',
        );
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
        if (mission.id != missionId) {
          throw CurriculumLoadException(
            'Mission IDs must not contain surrounding whitespace: $missionId',
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

        final hasWhitespacePrerequisite = mission.prerequisites
            .any((prerequisite) => prerequisite != prerequisite.trim());
        final prerequisites = mission.prerequisites
            .map((prerequisite) => prerequisite.trim())
            .where((prerequisite) => prerequisite.isNotEmpty)
            .toList(growable: false);
        if (hasWhitespacePrerequisite ||
            prerequisites.length != mission.prerequisites.length ||
            prerequisites.length != prerequisites.toSet().length ||
            prerequisites.contains(missionId)) {
          throw CurriculumLoadException(
            'Mission $missionId contains invalid prerequisite references.',
          );
        }
        prerequisitesByMission[missionId] = prerequisites;
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

    _validatePrerequisiteGraph(missionIds, prerequisitesByMission);
  }

  static void _validatePrerequisiteGraph(
    Set<String> missionIds,
    Map<String, List<String>> prerequisitesByMission,
  ) {
    final visitState = <String, int>{};

    void visit(String missionId) {
      final state = visitState[missionId] ?? 0;
      if (state == 1) {
        throw CurriculumLoadException(
          'Prerequisite graph contains a cycle involving mission $missionId.',
        );
      }
      if (state == 2) return;

      visitState[missionId] = 1;
      for (final prerequisite
          in prerequisitesByMission[missionId] ?? const []) {
        visit(prerequisite);
      }
      visitState[missionId] = 2;
    }

    for (final missionId in missionIds) {
      visit(missionId);
    }
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
