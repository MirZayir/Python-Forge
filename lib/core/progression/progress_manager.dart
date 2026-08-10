import 'package:shared_preferences/shared_preferences.dart';

/// Canonical, idempotent store of completed mission IDs.
///
/// Derived values (XP, level, unlocks, completion percentage) intentionally
/// live in [LearningProgressService] so there is exactly one source of truth.
class ProgressManager {
  static const String completedMissionsKey = 'completed_missions';
  static const String legacySuffix = '_completed';

  static const List<String> progressKeys = <String>[
    completedMissionsKey,
    'progress_total_xp',
    'max_unlocked_mission',
    'unlocked_achievements',
    'unlocked_achievement_times',
    'streak_current',
    'streak_longest',
    'streak_last_date',
    'streak_active_dates',
  ];

  Future<void> completeMission(String missionId) async {
    final id = missionId.trim();
    if (id.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final completed = await _readCompletedIds(prefs);
    if (completed.add(id)) {
      await prefs.setStringList(completedMissionsKey, completed.toList());
    }
  }

  Future<bool> isMissionCompleted(String missionId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await _readCompletedIds(prefs);
    return completed.contains(missionId.trim());
  }

  Future<Set<String>> completedMissionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return await _readCompletedIds(prefs);
  }

  Future<List<String>> getCompletedMissionIds() async {
    final ids = await completedMissionIds();
    return ids.toList(growable: false);
  }

  /// Removes IDs that are no longer present in the active curriculum.
  ///
  /// This protects derived XP/unlock calculations from stale content while
  /// preserving valid completion history across curriculum migrations.
  Future<Set<String>> sanitizeCompletedMissionIds(
    Set<String> validMissionIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readCompletedIds(prefs);
    final sanitized = current.intersection(validMissionIds);
    if (sanitized.length != current.length) {
      await prefs.setStringList(
        completedMissionsKey,
        sanitized.toList(growable: false),
      );
    }
    return sanitized;
  }

  Future<int> completedMissionCount() async {
    final ids = await completedMissionIds();
    return ids.length;
  }

  /// Removes progress data only, leaving user preferences untouched.
  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where(
            (key) => progressKeys.contains(key) || key.endsWith(legacySuffix))
        .toList(growable: false);

    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<Set<String>> _readCompletedIds(SharedPreferences prefs) async {
    final ids = <String>{
      ...(prefs.getStringList(completedMissionsKey) ?? const <String>[]),
    };

    // Migrate the safe legacy format `${missionId}_completed`. Numeric legacy
    // keys such as `mission_1_completed` are never inferred because they
    // collide across modules (m1_1 and m2_1 both contain 1).
    var migrated = false;
    for (final key in prefs.getKeys()) {
      if (key == completedMissionsKey ||
          !key.endsWith(legacySuffix) ||
          prefs.get(key) is! bool ||
          prefs.getBool(key) != true) {
        continue;
      }
      final id = key.substring(0, key.length - legacySuffix.length);
      if (id.isEmpty || id.startsWith('mission_')) continue;
      if (ids.add(id)) migrated = true;
    }

    final normalized = ids.where((id) => id.trim().isNotEmpty).toSet();
    final stored = prefs.getStringList(completedMissionsKey);
    if (migrated || stored == null || stored.length != normalized.length) {
      await prefs.setStringList(completedMissionsKey, normalized.toList());
    }
    return normalized;
  }
}
