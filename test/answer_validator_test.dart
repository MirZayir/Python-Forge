import 'package:flutter_test/flutter_test.dart';
import 'package:python_forge/core/engine/answer_validator.dart';
import 'package:python_forge/features/curriculum/domain/models/mission.dart';

Mission _mission({
  required MissionType type,
  required List<String> validAnswers,
  String expectedOutput = '',
}) {
  return Mission(
    id: 'test_mission',
    title: 'Test mission',
    description: 'Test mission',
    objective: 'Test mission',
    type: type,
    expectedOutput: expectedOutput,
    validationRules: ValidationRules(
      type: 'exact_match',
      validAnswers: validAnswers,
    ),
  );
}

void main() {
  test('runtime failure can never complete a code mission', () {
    final result = AnswerValidator.validate(
      fullCode: 'print("Hello")',
      actualOutput: 'Hello',
      mission: _mission(
        type: MissionType.code,
        validAnswers: ['print("Hello")'],
        expectedOutput: 'Hello',
      ),
      isError: true,
    );

    expect(result.status, ValidationStatus.incorrect);
  });

  test('code missions require both declared output and source contract', () {
    final mission = _mission(
      type: MissionType.code,
      validAnswers: ['print("Hello")'],
      expectedOutput: 'Hello',
    );

    expect(
      AnswerValidator.validate(
        fullCode: 'print("Hello")',
        actualOutput: 'Hello',
        mission: mission,
      ).status,
      ValidationStatus.correct,
    );
    expect(
      AnswerValidator.validate(
        fullCode: 'print("Hello")',
        actualOutput: 'Wrong',
        mission: mission,
      ).status,
      ValidationStatus.incorrect,
    );
  });

  test('MCQ and fill-in missions validate their own answer contracts', () {
    final mcq = _mission(
      type: MissionType.mcq,
      validAnswers: ['True'],
    );
    final fill = _mission(
      type: MissionType.fillInBlank,
      validAnswers: ['self'],
    );

    expect(
      AnswerValidator.validate(
        fullCode: 'true',
        actualOutput: '',
        mission: mcq,
      ).status,
      ValidationStatus.correct,
    );
    expect(
      AnswerValidator.validate(
        fullCode: 'self',
        actualOutput: 'self',
        mission: fill,
      ).status,
      ValidationStatus.correct,
    );
  });
}
