import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:python_forge/core/services/settings_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('clamps corrupt editor font sizes before exposing them', () async {
    SharedPreferences.setMockInitialValues({
      SettingsService.keyFontSize: 99.0,
    });

    final size = await SettingsService().getEditorFontSize();

    expect(size, SettingsService.maxEditorFontSize);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble(SettingsService.keyFontSize),
        SettingsService.maxEditorFontSize);
  });

  test('progress reset preserves user preferences', () async {
    SharedPreferences.setMockInitialValues({
      SettingsService.keyHaptics: false,
      SettingsService.keyFontSize: 18.0,
      'completed_missions': ['m1_1'],
      'streak_active_dates': ['2026-08-10'],
    });

    await SettingsService().resetAllProgress();
    final prefs = await SharedPreferences.getInstance();

    expect(prefs.getBool(SettingsService.keyHaptics), isFalse);
    expect(prefs.getDouble(SettingsService.keyFontSize), 18.0);
    expect(prefs.getStringList('completed_missions'), isNull);
    expect(prefs.getStringList('streak_active_dates'), isNull);
  });
}
