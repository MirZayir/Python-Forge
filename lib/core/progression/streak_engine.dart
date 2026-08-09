import 'package:shared_preferences/shared_preferences.dart';

/// Immutable snapshot of streak state derived from persisted activity dates.
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final Set<String> activeDates;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
    this.activeDates = const {},
  });

  bool isActiveOn(DateTime day) =>
      activeDates.contains(StreakEngine.dateKey(day));
}

/// Streak tracking backed by real per-day activity records.
class StreakEngine {
  static const String activeDatesKey = 'streak_active_dates';
  static const int _maxStoredDays = 400;

  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<StreakData> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final dates = _readDates(prefs)..add(dateKey(DateTime.now()));

    final ordered = dates.toList()..sort();
    final trimmed = ordered.length > _maxStoredDays
        ? ordered.sublist(ordered.length - _maxStoredDays)
        : ordered;

    await prefs.setStringList(activeDatesKey, trimmed);
    return _buildData(trimmed.toSet());
  }

  Future<StreakData> getStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    return _buildData(_readDates(prefs));
  }

  Set<String> _readDates(SharedPreferences prefs) {
    final stored = prefs.getStringList(activeDatesKey);
    if (stored != null) return stored.toSet();

    // Migrate the previous single-date format so existing streaks survive.
    final legacyDate = prefs.getString('streak_last_date');
    if (legacyDate == null) return <String>{};
    final parsed = DateTime.tryParse(legacyDate);
    if (parsed == null) return <String>{};

    final legacyStreak = prefs.getInt('streak_current') ?? 1;
    final migrated = <String>{};
    for (var offset = 0; offset < legacyStreak.clamp(1, 60); offset++) {
      migrated.add(dateKey(parsed.subtract(Duration(days: offset))));
    }
    return migrated;
  }

  StreakData _buildData(Set<String> dates) {
    if (dates.isEmpty) {
      return const StreakData(currentStreak: 0, longestStreak: 0);
    }

    final parsed = dates
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .toList()
      ..sort();

    if (parsed.isEmpty) {
      return const StreakData(currentStreak: 0, longestStreak: 0);
    }

    var longest = 1;
    var run = 1;
    for (var index = 1; index < parsed.length; index++) {
      final gap = parsed[index].difference(parsed[index - 1]).inDays;
      run = gap == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final latest = parsed.last;
    final daysSinceLatest = today.difference(latest).inDays;

    var current = 0;
    if (daysSinceLatest <= 1) {
      current = 1;
      for (var index = parsed.length - 1; index > 0; index--) {
        if (parsed[index].difference(parsed[index - 1]).inDays == 1) {
          current++;
        } else {
          break;
        }
      }
    }

    return StreakData(
      currentStreak: current,
      longestStreak: longest,
      lastActiveDate: latest,
      activeDates: parsed.map(dateKey).toSet(),
    );
  }
}
