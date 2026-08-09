import 'package:flutter_test/flutter_test.dart';
import 'package:python_forge/core/progression/learning_progress.dart';
import 'package:python_forge/features/curriculum/domain/models/curriculum.dart';
import 'package:python_forge/features/curriculum/domain/models/mission.dart';
import 'package:python_forge/features/curriculum/domain/models/module.dart';

Mission _mission(String id) => Mission(
      id: id,
      title: 'Mission $id',
      description: '',
      objective: '',
      type: MissionType.code,
      validationRules: const ValidationRules(
        type: 'exact_match',
        validAnswers: ['print("x")'],
      ),
    );

final _curriculum = Curriculum(
  title: 'Test',
  description: 'Test',
  modules: [
    Module(
      moduleId: 'mod_1',
      title: 'Module 1',
      description: '',
      order: 1,
      missions: [_mission('m1_1'), _mission('m1_2')],
    ),
    Module(
      moduleId: 'mod_2',
      title: 'Module 2',
      description: '',
      order: 2,
      missions: [_mission('m2_1')],
    ),
  ],
);

void main() {
  test('only the first mission is unlocked for a new learner', () {
    final progress = LearningProgressService.build(
      curriculum: _curriculum,
      completedMissionIds: const {},
    );

    expect(progress.isMissionUnlocked('m1_1'), isTrue);
    expect(progress.isMissionUnlocked('m1_2'), isFalse);
    expect(progress.isMissionUnlocked('m2_1'), isFalse);
    expect(progress.nextMission?.id, 'm1_1');
    expect(progress.totalXp, 0);
    expect(progress.completionPercent, 0);
  });

  test('completing a mission unlocks the next and advances resume', () {
    final progress = LearningProgressService.build(
      curriculum: _curriculum,
      completedMissionIds: const {'m1_1'},
    );

    expect(progress.isMissionUnlocked('m1_2'), isTrue);
    expect(progress.isMissionUnlocked('m2_1'), isFalse);
    expect(progress.nextMission?.id, 'm1_2');
    expect(progress.completedMissionCount, 1);
    expect(progress.totalXp, greaterThan(0));
    expect(progress.progressForModule('mod_1').completedCount, 1);
    expect(progress.progressForModule('mod_2').isUnlocked, isFalse);
  });

  test('finishing a module unlocks the following module', () {
    final progress = LearningProgressService.build(
      curriculum: _curriculum,
      completedMissionIds: const {'m1_1', 'm1_2'},
    );

    expect(progress.progressForModule('mod_1').isCompleted, isTrue);
    expect(progress.progressForModule('mod_2').isUnlocked, isTrue);
    expect(progress.nextMission?.id, 'm2_1');
  });

  test('full completion reports no next mission', () {
    final progress = LearningProgressService.build(
      curriculum: _curriculum,
      completedMissionIds: const {'m1_1', 'm1_2', 'm2_1'},
    );

    expect(progress.isFullyCompleted, isTrue);
    expect(progress.nextMission, isNull);
    expect(progress.completionPercent, 1.0);
    expect(progress.missionAfter('m1_2')?.id, 'm2_1');
  });
}
