/// Date / time helpers operating in the device's local timezone.
///
/// Habits, completions and streaks are intrinsically calendar-day concepts,
/// so we work with **local** dates throughout. All "date" values returned by
/// these helpers have their time component zeroed (local midnight).
class TimeUtils {
  TimeUtils._();

  /// Current local instant.
  static DateTime now() => DateTime.now();

  /// Local midnight of the day [dt] falls on.
  static DateTime toDate(DateTime dt) {
    final local = dt.isUtc ? dt.toLocal() : dt;
    return DateTime(local.year, local.month, local.day);
  }

  /// Local Monday-midnight of the week containing [dt].
  static DateTime weekStart(DateTime dt) {
    final d = toDate(dt);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  /// Whether [a] and [b] are the same local calendar day.
  static bool isSameDate(DateTime a, DateTime b) {
    final da = toDate(a);
    final db = toDate(b);
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }
}
