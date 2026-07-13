/// Utilities for deterministic date-keyed logic, primarily the Daily
/// Word feature — ensures the same word is shown all day, to every
/// user on that date, without needing a server.
class AppDateUtils {
  AppDateUtils._();

  /// Returns a stable integer seed derived from today's date
  /// (e.g. 20260707 for July 7, 2026). Used to deterministically pick
  /// the same "random" word all day via WordDao.getRandomWord(seed:).
  static int todaySeed() {
    final now = DateTime.now();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  static String todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}