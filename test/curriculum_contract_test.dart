import 'package:flutter_test/flutter_test.dart';
import 'package:python_forge/features/curriculum/data/repositories/curriculum_repository.dart';
import 'package:python_forge/features/curriculum/domain/models/curriculum.dart';
import 'package:python_forge/features/curriculum/domain/models/mission.dart';
import 'package:python_forge/features/curriculum/domain/models/module.dart';

Mission _mission({
  String id = 'test_mission',
  String title = 'Test mission',
  MissionType type = MissionType.code,
  List<String> validAnswers = const ['print("ok")'],
  List<String> prerequisites = const [],
  List<String>? mcqOptions,
}) {
  return Mission(
    id: id,
    title: title,
    description: 'A valid test mission description.',
    objective: 'Complete the test mission objective.',
    type: type,
    prerequisites: prerequisites,
    mcqOptions: mcqOptions,
    validationRules: ValidationRules(
      type: 'exact_match',
      validAnswers: validAnswers,
    ),
  );
}

Curriculum _curriculum(
  Mission mission, {
  List<Mission> additionalMissions = const [],
}) {
  return Curriculum(
    title: 'Test curriculum',
    description: 'A valid test curriculum description.',
    modules: [
      Module(
        moduleId: 'test_module',
        title: 'Test module',
        description: 'A valid test module description.',
        order: 1,
        missions: [mission, ...additionalMissions],
      ),
    ],
  );
}

void expectInvalid(Curriculum curriculum) {
  expect(
    () => CurriculumRepository().validateCurriculum(curriculum),
    throwsA(isA<CurriculumLoadException>()),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled curriculum parses its real top-level list', () async {
    final curriculum = await CurriculumRepository().getCurriculum();

    expect(curriculum.modules, hasLength(8));
    expect(
      curriculum.modules.expand((module) => module.missions).toList(),
      hasLength(40),
    );
    expect(curriculum.modules.first.moduleId, 'mod_1');
    expect(curriculum.modules.first.missions.first.validAnswers, isNotEmpty);
    expect(curriculum.modules.first.missions.first.type, MissionType.code);
  });

  test('rejects an MCQ answer that is missing from its options', () {
    expectInvalid(
      _curriculum(
        _mission(
          type: MissionType.mcq,
          validAnswers: const ['missing'],
          mcqOptions: const ['available'],
        ),
      ),
    );
  });

  test('rejects unknown prerequisite references', () {
    expectInvalid(
      _curriculum(_mission(prerequisites: const ['does_not_exist'])),
    );
  });

  test('rejects non-canonical prerequisite whitespace', () {
    expectInvalid(
      _curriculum(
        _mission(prerequisites: const [' test_mission_2 ']),
        additionalMissions: [_mission(id: 'test_mission_2')],
      ),
    );
  });

  test('rejects prerequisite cycles', () {
    expectInvalid(
      _curriculum(
        _mission(id: 'mission_a', prerequisites: const ['mission_b']),
        additionalMissions: [
          _mission(id: 'mission_b', prerequisites: const ['mission_a']),
        ],
      ),
    );
  });

  test('rejects missions with required fields missing', () {
    expectInvalid(_curriculum(_mission(title: '')));
  });
}
