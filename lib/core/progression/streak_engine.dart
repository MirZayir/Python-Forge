import 'package:shared_preferences/shared_preferences.dart';

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;

  const StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });
}

class StreakEngine {
  static const String _keyCurrentStreak = 'streak_current';
  static const String _keyLongestStreak = 'streak_longest';
  static const String _keyLastActiveDate = 'streak_last_date';

  /// Records activity for today and updates streak status.
  Future<StreakData> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int current = prefs.getInt(_keyCurrentStreak) ?? 0;
    int longest = prefs.getInt(_keyLongestStreak) ?? 0;
    final lastDateStr = prefs.getString(_keyLastActiveDate);

    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      final differenceInDays = today.difference(lastDate).inDays;

      if (differenceInDays == 1) {
        // Active on consecutive day
        current += 1;
      } else if (differenceInDays > 1) {
        // Streak broken
        current = 1;
      }
      // If differenceInDays == 0, user already active today; keep current streak unchanged
    } else {
      // First activity ever recorded
      current = 1;
    }

    if (current > longest) {
      longest = current;
    }

    await prefs.setInt(_keyCurrentStreak, current);
    await prefs.setInt(_keyLongestStreak, longest);
    await prefs.setString(_keyLastActiveDate, today.toIso8601String());

    return StreakData(
      currentStreak: current,
      longestStreak: longest,
      lastActiveDate: today,
    );
  }

  /// Fetches current streak statistics without modifying state.
  Future<StreakData> getStreakData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int current = prefs.getInt(_keyCurrentStreak) ?? 0;
    final longest = prefs.getInt(_keyLongestStreak) ?? 0;
    final lastDateStr = prefs.getString(_keyLastActiveDate);

    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      final differenceInDays = today.difference(lastDate).inDays;

      if (differenceInDays > 1) {
        current = 0; // Streak expired
      }
    }

    return StreakData(
      currentStreak: current,
      longestStreak: longest,
      lastActiveDate: lastDateStr != null ? DateTime.parse(lastDateStr) : null,
    );
  }
}
