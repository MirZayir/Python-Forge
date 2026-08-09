import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:python_forge/core/progression/achievement_catalog.dart';
import 'package:python_forge/core/progression/achievement_engine.dart';
import 'package:python_forge/core/progression/streak_engine.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('recording activity twice today keeps a single day streak', () async {
    final engine = StreakEngine();

    await engine.recordActivity();
    final data = await engine.recordActivity();

    expect(data.currentStreak, 1);
    expect(data.longestStreak, 1);
    expect(data.isActiveOn(DateTime.now()), isTrue);
  });

  test('consecutive stored days produce a multi-day streak', () async {
    final today = DateTime.now();
    SharedPreferences.setMockInitialValues({
      StreakEngine.activeDatesKey: [
        StreakEngine.dateKey(today.subtract(const Duration(days: 2))),
        StreakEngine.dateKey(today.subtract(const Duration(days: 1))),
        StreakEngine.dateKey(today),
      ],
    });

    final data = await StreakEngine().getStreakData();

    expect(data.currentStreak, 3);
    expect(data.longestStreak, 3);
  });

  test('a long gap resets the current streak but keeps the longest', () async {
    final today = DateTime.now();
    SharedPreferences.setMockInitialValues({
      StreakEngine.activeDatesKey: [
        StreakEngine.dateKey(today.subtract(const Duration(days: 30))),
        StreakEngine.dateKey(today.subtract(const Duration(days: 29))),
      ],
    });

    final data = await StreakEngine().getStreakData();

    expect(data.currentStreak, 0);
    expect(data.longestStreak, 2);
  });

  test('achievements unlock once and use the shared catalog IDs', () async {
    final engine = AchievementEngine();

    final first = await engine.evaluateAndUnlock(
      const AchievementMetrics(completedMissionCount: 1),
    );
    final repeat = await engine.evaluateAndUnlock(
      const AchievementMetrics(completedMissionCount: 1),
    );

    expect(first.map((a) => a.id), contains('first_mission'));
    expect(repeat, isEmpty);

    final unlocked = await engine.getUnlockedAchievements();
    expect(unlocked.map((a) => a.id), contains('first_mission'));

    final catalogIds = AchievementCatalog.all.map((a) => a.id).toSet();
    final unlockedIds = await engine.unlockedIds();
    expect(catalogIds.containsAll(unlockedIds), isTrue);
  });

  test('streak and XP achievements are reachable', () async {
    final engine = AchievementEngine();

    final unlocked = await engine.evaluateAndUnlock(
      const AchievementMetrics(
        completedMissionCount: 10,
        totalXp: 500,
        currentStreak: 3,
      ),
    );

    expect(
      unlocked.map((a) => a.id),
      containsAll(<String>['streak_3', 'xp_500', 'scholar']),
    );
  });
}
