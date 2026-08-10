import '../../features/curriculum/data/repositories/curriculum_repository.dart';
import '../../features/curriculum/domain/models/curriculum.dart';
import '../../features/curriculum/domain/models/mission.dart';
import '../../features/curriculum/domain/models/module.dart';
import 'progress_manager.dart';
import 'xp_manager.dart';

/// Progress rollup for a single module.
class ModuleProgress {
  final Module module;
  final int completedCount;
  final bool isUnlocked;

  const ModuleProgress({
    required this.module,
    required this.completedCount,
    required this.isUnlocked,
  });

  int get totalCount => module.missions.length;
  bool get isCompleted => totalCount > 0 && completedCount >= totalCount;
  double get completionPercent =>
      totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);
}

/// Single derived view of the learner journey.
///
/// Every progress-dependent value in the app is computed here so XP, levels,
/// unlocks, resume position, and completion counts can never disagree.
class LearningProgress {
  final Curriculum curriculum;
  final Set<String> completedMissionIds;
  final Set<String> unlockedMissionIds;
  final List<ModuleProgress> moduleProgress;
  final int totalXp;
  final Mission? nextMission;
  final Module? nextModule;

  const LearningProgress({
    required this.curriculum,
    required this.completedMissionIds,
    required this.unlockedMissionIds,
    required this.moduleProgress,
    required this.totalXp,
    this.nextMission,
    this.nextModule,
  });

  List<Module> get modules => curriculum.modules;

  int get totalMissionCount =>
      curriculum.modules.fold(0, (sum, module) => sum + module.missions.length);

  int get completedMissionCount => curriculum.modules
      .expand((module) => module.missions)
      .where((mission) => completedMissionIds.contains(mission.id))
      .length;

  int get level => (totalXp ~/ 100) + 1;

  double get completionPercent => totalMissionCount == 0
      ? 0.0
      : (completedMissionCount / totalMissionCount).clamp(0.0, 1.0);

  bool get isFullyCompleted =>
      totalMissionCount > 0 && completedMissionCount >= totalMissionCount;

  bool isMissionCompleted(String missionId) =>
      completedMissionIds.contains(missionId);

  bool isMissionUnlocked(String missionId) =>
      unlockedMissionIds.contains(missionId);

  ModuleProgress progressForModule(String moduleId) {
    for (final progress in moduleProgress) {
      if (progress.module.moduleId == moduleId) return progress;
    }
    return ModuleProgress(
      module: Module(
        moduleId: moduleId,
        title: '',
        description: '',
        missions: const [],
      ),
      completedCount: 0,
      isUnlocked: false,
    );
  }

  /// Returns the next valid, incomplete mission after [missionId].
  ///
  /// A plain list successor is not safe when a curriculum introduces explicit
  /// prerequisites, so the derived unlock set is respected here as well.
  Mission? missionAfter(String missionId) {
    final ordered = curriculum.modules
        .expand((module) => module.missions)
        .toList(growable: false);
    var found = false;
    for (final mission in ordered) {
      if (found && unlockedMissionIds.contains(mission.id)) {
        return mission;
      }
      if (mission.id == missionId) found = true;
    }
    return null;
  }

  Module? moduleOf(String missionId) {
    for (final module in curriculum.modules) {
      if (module.missions.any((mission) => mission.id == missionId)) {
        return module;
      }
    }
    return null;
  }
}

/// Builds [LearningProgress] from the curriculum and stored completion IDs.
class LearningProgressService {
  final CurriculumRepository _curriculumRepository;
  final ProgressManager _progressManager;

  LearningProgressService({
    CurriculumRepository? curriculumRepository,
    ProgressManager? progressManager,
  })  : _curriculumRepository = curriculumRepository ?? CurriculumRepository(),
        _progressManager = progressManager ?? ProgressManager();

  Future<LearningProgress> load() async {
    final curriculum = await _curriculumRepository.getCurriculum();
    final validMissionIds = curriculum.modules
        .expand((module) => module.missions)
        .map((mission) => mission.id)
        .toSet();
    final completed = await _progressManager.sanitizeCompletedMissionIds(
      validMissionIds,
    );
    return build(curriculum: curriculum, completedMissionIds: completed);
  }

  /// Pure derivation, exposed separately so it is directly testable.
  static LearningProgress build({
    required Curriculum curriculum,
    required Set<String> completedMissionIds,
  }) {
    final ordered = curriculum.modules
        .expand((module) => module.missions)
        .toList(growable: false);
    final knownMissionIds = ordered.map((mission) => mission.id).toSet();
    final completed = completedMissionIds.intersection(knownMissionIds);

    final unlocked = <String>{};
    for (var index = 0; index < ordered.length; index++) {
      final mission = ordered[index];
      final previousGate =
          index == 0 || completed.contains(ordered[index - 1].id);
      final prerequisiteGate = mission.prerequisites.isEmpty ||
          mission.prerequisites.every(completed.contains);

      if (completed.contains(mission.id) ||
          (previousGate && prerequisiteGate)) {
        unlocked.add(mission.id);
      }
    }

    var totalXp = 0;
    for (final mission in ordered) {
      if (completed.contains(mission.id)) {
        totalXp += XpManager.rewardFor(mission);
      }
    }

    final moduleProgress = curriculum.modules.map((module) {
      final completedInModule = module.missions
          .where((mission) => completed.contains(mission.id))
          .length;
      final moduleUnlocked =
          module.missions.any((mission) => unlocked.contains(mission.id));
      return ModuleProgress(
        module: module,
        completedCount: completedInModule,
        isUnlocked: moduleUnlocked,
      );
    }).toList(growable: false);

    Mission? nextMission;
    for (final mission in ordered) {
      if (!completed.contains(mission.id) && unlocked.contains(mission.id)) {
        nextMission = mission;
        break;
      }
    }

    Module? nextModule;
    if (nextMission != null) {
      for (final module in curriculum.modules) {
        if (module.missions.any((mission) => mission.id == nextMission!.id)) {
          nextModule = module;
          break;
        }
      }
    }

    return LearningProgress(
      curriculum: curriculum,
      completedMissionIds: completed,
      unlockedMissionIds: unlocked,
      moduleProgress: moduleProgress,
      totalXp: totalXp,
      nextMission: nextMission,
      nextModule: nextModule,
    );
  }
}
