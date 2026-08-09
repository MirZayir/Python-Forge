import 'package:flutter_test/flutter_test.dart';
import 'package:python_forge/features/curriculum/data/repositories/curriculum_repository.dart';
import 'package:python_forge/features/curriculum/domain/models/mission.dart';

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
}
