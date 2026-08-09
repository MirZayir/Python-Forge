import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:python_forge/features/curriculum/domain/models/mission.dart';
import 'package:python_forge/features/curriculum/presentation/screens/mission_screen.dart';

const _codeMission = Mission(
  id: 'm1_1',
  title: 'Hello World',
  description: 'Every programmer starts here.',
  objective: 'Print exactly "Hello, World!" to the console.',
  type: MissionType.code,
  starterCode: '# Print your first output below',
  hints: ['Use the print() function.'],
  validationRules: ValidationRules(
    type: 'exact_match',
    validAnswers: ['print("Hello, World!")'],
  ),
);

const _mcqMission = Mission(
  id: 'm1_2',
  title: 'Variables Quiz',
  description: 'Test your understanding.',
  objective: 'Which assignment is valid?',
  type: MissionType.mcq,
  mcqOptions: ['25 = user_age', 'user_age = 25'],
  validationRules: ValidationRules(
    type: 'exact_match',
    validAnswers: ['user_age = 25'],
  ),
);

const _fillMission = Mission(
  id: 'm1_4',
  title: 'Floats Check',
  description: 'Identify decimal types.',
  objective: 'Fill in the blank to store 3.14.',
  type: MissionType.fillInBlank,
  starterCode: 'pi = ___',
  validationRules: ValidationRules(
    type: 'exact_match',
    validAnswers: ['3.14'],
  ),
);

void _useLargeSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('code mission renders its objective, editor and actions',
      (tester) async {
    _useLargeSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: MissionScreen(mission: _codeMission)),
    );
    await tester.pump();

    expect(find.text('Hello World'), findsOneWidget);
    expect(find.text('Every programmer starts here.'), findsOneWidget);
    expect(
      find.text('Print exactly "Hello, World!" to the console.'),
      findsOneWidget,
    );
    expect(find.text('EDITOR'), findsOneWidget);
    expect(find.text('CONSOLE'), findsOneWidget);
    expect(find.text('Run Code'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('MCQ mission renders every option', (tester) async {
    _useLargeSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: MissionScreen(mission: _mcqMission)),
    );
    await tester.pump();

    expect(find.text('Select the correct answer:'), findsOneWidget);
    expect(find.text('25 = user_age'), findsOneWidget);
    expect(find.text('user_age = 25'), findsOneWidget);
    expect(find.text('Submit Answer'), findsOneWidget);
  });

  testWidgets('fill-in-the-blank mission renders its input', (tester) async {
    _useLargeSurface(tester);

    await tester.pumpWidget(
      const MaterialApp(home: MissionScreen(mission: _fillMission)),
    );
    await tester.pump();

    expect(find.text('Submit Answer'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets);
  });
}
