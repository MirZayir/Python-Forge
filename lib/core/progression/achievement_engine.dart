import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'achievement.dart';
import 'achievement_catalog.dart';

/// Evaluates learner metrics and unlocks achievements from the shared catalog.
class AchievementEngine {
  static const String unlockedKey = 'unlocked_achievements';
  static const String unlockedAtKey = 'unlocked_achievement_times';

  Future<Set<String>> unlockedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        (prefs.getStringList(unlockedKey) ?? const <String>[]).toSet();
    final knownIds =
        AchievementCatalog.definitions.map((item) => item.id).toSet();
    final known = stored.intersection(knownIds);

    // Quarantine IDs from old catalogs so the UI never reports phantom badges.
    if (known.length != stored.length) {
      await prefs.setStringList(unlockedKey, _orderedIds(known));
    }
    return known;
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await unlockedIds();
    final timestamps = _readTimestamps(prefs);
    final definitions = AchievementCatalog.definitions
        .where((definition) => ids.contains(definition.id))
        .toList(growable: false);

    final catalogOrder = <String, int>{};
    for (var index = 0;
        index < AchievementCatalog.definitions.length;
        index++) {
      catalogOrder[AchievementCatalog.definitions[index].id] = index;
    }
    final ordered = [...definitions]..sort((a, b) {
        final byTime = (timestamps[b.id] ?? 0).compareTo(timestamps[a.id] ?? 0);
        if (byTime != 0) return byTime;
        return (catalogOrder[a.id] ?? 0).compareTo(catalogOrder[b.id] ?? 0);
      });

    return ordered.map((definition) => definition.achievement).toList();
  }

  /// Unlocks any newly earned achievements and returns only the new ones.
  ///
  /// Unlock timestamps make the profile's "recent" section deterministic,
  /// while the catalog remains the source of truth for definitions.
  Future<List<Achievement>> evaluateAndUnlock(
    AchievementMetrics metrics,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        (prefs.getStringList(unlockedKey) ?? const <String>[]).toSet();
    final knownIds =
        AchievementCatalog.definitions.map((item) => item.id).toSet();
    final unlocked = stored.intersection(knownIds);
    final timestamps = _readTimestamps(prefs);
    final newlyUnlocked = <Achievement>[];
    var timestamp = DateTime.now().toUtc().millisecondsSinceEpoch;

    for (final definition in AchievementCatalog.definitions) {
      if (unlocked.contains(definition.id) || !definition.isEarned(metrics)) {
        continue;
      }
      unlocked.add(definition.id);
      timestamps[definition.id] = timestamp++;
      newlyUnlocked.add(definition.achievement);
    }

    if (newlyUnlocked.isNotEmpty || stored.length != unlocked.length) {
      await prefs.setStringList(unlockedKey, _orderedIds(unlocked));
      await prefs.setString(unlockedAtKey, jsonEncode(timestamps));
    }
    return newlyUnlocked;
  }

  static List<String> _orderedIds(Set<String> ids) =>
      AchievementCatalog.definitions
          .map((definition) => definition.id)
          .where(ids.contains)
          .toList(growable: false);

  static Map<String, int> _readTimestamps(SharedPreferences prefs) {
    final raw = prefs.getString(unlockedAtKey);
    if (raw == null) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return <String, int>{};
      return decoded.map((key, value) {
        return MapEntry(key, value is num ? value.toInt() : 0);
      });
    } catch (_) {
      return <String, int>{};
    }
  }
}
