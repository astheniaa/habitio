class TimeUtils {
  static const _utc3Offset = Duration(hours: 3);

  static DateTime nowUtc3() => DateTime.now().toUtc().add(_utc3Offset);

  static DateTime toUtc3Date(DateTime dt) {
    final utc3 = dt.toUtc().add(_utc3Offset);
    return DateTime.utc(utc3.year, utc3.month, utc3.day);
  }

  static DateTime weekStartUtc3(DateTime dt) {
    final utc3Date = toUtc3Date(dt);
    final daysFromMonday = utc3Date.weekday - 1;
    return utc3Date.subtract(Duration(days: daysFromMonday));
  }

  static bool isSameUtc3Date(DateTime a, DateTime b) {
    final dateA = toUtc3Date(a);
    final dateB = toUtc3Date(b);
    return dateA.year == dateB.year &&
        dateA.month == dateB.month &&
        dateA.day == dateB.day;
  }
}
