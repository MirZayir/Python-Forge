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
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
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
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.text('RESUME LEARNING'),
      maxFrames: 120,
    );
    expect(find.text('RESUME LEARNING'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, const Color(0xFFFAF8F5));
  });

  testWidgets('dashboard survives a narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: PythonForgeApp()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.text('RESUME LEARNING'),
      maxFrames: 120,
    );

    expect(find.text('RESUME LEARNING'), findsOneWidget);

    final curriculumHeading = find.text('My Curriculum');
    await tester.scrollUntilVisible(
      curriculumHeading,
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('FORGE'), findsOneWidget);
    expect(curriculumHeading, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard survives large text scaling', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const ProviderScope(child: PythonForgeApp()));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();
    await _pumpUntilFound(
      tester,
      find.text('RESUME LEARNING'),
      maxFrames: 120,
    );

    expect(find.text('RESUME LEARNING'), findsOneWidget);

    final curriculumHeading = find.text('My Curriculum');
    await tester.scrollUntilVisible(
      curriculumHeading,
      500,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('PYTHON FORGE'), findsOneWidget);
    expect(curriculumHeading, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
