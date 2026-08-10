import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:python_forge/features/curriculum/domain/models/mission.dart';
import 'package:python_forge/features/curriculum/presentation/screens/mission_screen.dart';

Mission _mission(String id) => Mission(
      id: id,
      title: 'Untrusted mission',
      description: 'This object must be resolved against the asset.',
      objective: 'Never execute an unknown route extra.',
      type: MissionType.code,
      validationRules: const ValidationRules(
        type: 'exact_match',
        validAnswers: ['print("ok")'],
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  for (var index = 0; index < 100; index++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('Mission locked').evaluate().isNotEmpty) return;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('entry screen rejects an unknown mission route extra',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MissionEntryScreen(mission: _mission('unknown'))),
    );
    await _settle(tester);

    expect(find.text('Mission locked'), findsOneWidget);
    expect(find.text('Untrusted mission'), findsNothing);
  });
}
