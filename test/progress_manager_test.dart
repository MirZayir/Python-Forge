import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:python_forge/core/progression/progress_manager.dart';
import 'package:python_forge/core/services/settings_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'haptics_enabled': false,
      'editor_font_size': 16.0,
    });
  });

  test('completion is unique by full mission ID', () async {
    final manager = ProgressManager();

    await manager.completeMission('m1_1');
    await manager.completeMission('m1_1');
    await manager.completeMission('m2_1');

    expect(await manager.completedMissionCount(), 2);
    expect(await manager.isMissionCompleted('m1_1'), isTrue);
    expect(await manager.isMissionCompleted('m2_1'), isTrue);
    expect(await manager.isMissionCompleted('m3_1'), isFalse);
  });

  test('legacy id keys migrate without colliding across modules', () async {
    SharedPreferences.setMockInitialValues({
      'm1_1_completed': true,
      'm2_1_completed': true,
      'mission_1_completed': true,
    });

    final manager = ProgressManager();
    final ids = await manager.completedMissionIds();

    expect(ids, containsAll(<String>['m1_1', 'm2_1']));
    expect(ids.any((id) => id.startsWith('mission_')), isFalse);
  });

  test('reset removes progress but preserves preferences', () async {
    final settings = SettingsService();
    final manager = ProgressManager();

    await manager.completeMission('m1_1');
    await manager.resetProgress();

    expect(await manager.completedMissionCount(), 0);
    expect(await settings.isHapticsEnabled(), isFalse);
    expect(await settings.getEditorFontSize(), 16.0);
  });
}
