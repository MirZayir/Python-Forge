import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:python_forge/main.dart';

/// Pumps frames until [finder] matches, without waiting for the indeterminate
/// loading spinner to settle.
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxFrames = 40,
}) async {
  for (var frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('cold start renders the home dashboard with real curriculum',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PythonForgeApp()));
    await _pumpUntilFound(tester, find.text('My Curriculum'));

    // Root screen identity.
    expect(find.text('PYTHON FORGE'), findsOneWidget);
    expect(find.text('Forge code.\nMaster Python.'), findsOneWidget);
    expect(find.text('My Curriculum'), findsOneWidget);
    expect(find.text('Unable to load curriculum data'), findsNothing);

    // Dashboard actions exist so profile, settings, and console are reachable.
    expect(find.byTooltip('Quick console'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Profile'), findsOneWidget);
    expect(find.byTooltip('Learning streak'), findsOneWidget);

    // Real curriculum content and progression state.
    expect(find.text('RESUME LEARNING'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
    expect(find.text('Python Foundations'), findsOneWidget);
    expect(find.text('0/5 missions complete • 1.0 hrs'), findsOneWidget);
    expect(find.text('Control Flow & Decisions'), findsOneWidget);
    expect(find.text('LOCKED'), findsWidgets);
    expect(find.text('0 XP earned'), findsOneWidget);
  });

  testWidgets('dashboard uses the cream neubrutalist theme', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PythonForgeApp()));
    await _pumpUntilFound(tester, find.text('My Curriculum'));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFFFAF8F5));
  });
}
