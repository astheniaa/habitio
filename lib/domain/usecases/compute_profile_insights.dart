import '../models/entities/category.dart';
import '../models/entities/habit.dart';
import '../models/entities/habit_completion.dart';
import '../models/profile_insights.dart';
import '../utils/time_utils.dart';

/// Computes the data the ProfileScreen renders: streaks, today's snapshot,
/// per-category recent progress, and a small list of dynamic insights.
///
/// All progress math uses a 14-day window so categories that haven't been
/// touched in months don't pull the picture down — this is a "personal
/// progress dashboard", not a lifetime ledger.
class ComputeProfileInsightsUseCase {
  /// Window used for category progress + day-of-week patterns.
  static const _window = Duration(days: 14);

  /// "Strong" / "weak" thresholds for category insights.
  static const _strongRatio = 0.75;
  static const _weakRatio = 0.40;

  /// Minimum scheduled days a category needs in the window to be a candidate
  /// for a strong/weak insight. Avoids surfacing categories with one data
  /// point.
  static const _minScheduledForInsight = 4;

  ProfileInsightsResult call({
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required List<Category> categories,
  }) {
    final now = TimeUtils.now();
    final today = TimeUtils.toDate(now);
    final windowStart =
        today.subtract(_window).add(const Duration(days: 1)); // inclusive

    final activeHabits = habits.where((h) => !h.isArchived).toList();
    final completedDates = _completedDateSet(completions);

    // ── Streaks (activity streak across all habits) ─────────────────────────
    final activityStreak = _activityStreak(completedDates, today);
    final bestActivityStreak = _bestActivityStreak(completedDates, today);

    // ── Today snapshot ──────────────────────────────────────────────────────
    final todayScheduled =
        activeHabits.where((h) => _scheduledOn(h, today)).toList();
    final todayDoneCount = todayScheduled
        .where((h) => completions.any((c) =>
            c.habitId == h.id &&
            c.completed &&
            TimeUtils.isSameDate(c.date, today)))
        .length;
    final todaySnapshot = TodaySnapshot(
      completed: todayDoneCount,
      scheduled: todayScheduled.length,
    );

    // ── Per-category progress in the window ────────────────────────────────
    final categoryProgress = _categoryProgress(
      categories: categories,
      habits: activeHabits,
      completions: completions,
      from: windowStart,
      to: today,
    );

    // ── Insights ────────────────────────────────────────────────────────────
    final insights = _buildInsights(
      activityStreak: activityStreak,
      categoryProgress: categoryProgress,
      activeHabits: activeHabits,
      completions: completions,
      windowStart: windowStart,
      today: today,
    );

    return ProfileInsightsResult(
      currentStreak: activityStreak,
      bestStreak: bestActivityStreak,
      today: todaySnapshot,
      categories: categoryProgress,
      insights: insights,
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  //  Helpers
  // ───────────────────────────────────────────────────────────────────────

  Set<DateTime> _completedDateSet(List<HabitCompletion> completions) {
    final set = <DateTime>{};
    for (final c in completions) {
      if (!c.completed) continue;
      set.add(TimeUtils.toDate(c.date));
    }
    return set;
  }

  bool _scheduledOn(Habit habit, DateTime date) {
    if (habit.scheduleType == HabitScheduleType.everyday) return true;
    return habit.weekdays.contains(date.weekday);
  }

  /// Counts consecutive days with ≥1 completion ending today (or yesterday
  /// if today is empty — today is "in progress").
  int _activityStreak(Set<DateTime> completedDays, DateTime today) {
    var d = today;
    if (!completedDays.contains(d)) {
      d = d.subtract(const Duration(days: 1));
    }
    int streak = 0;
    while (completedDays.contains(d)) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Best historical activity streak across all completions (≥1/day).
  int _bestActivityStreak(Set<DateTime> completedDays, DateTime today) {
    if (completedDays.isEmpty) return 0;
    final sorted = completedDays.toList()..sort();
    int best = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      final gap = sorted[i].difference(sorted[i - 1]).inDays;
      if (gap == 1) {
        run++;
        if (run > best) best = run;
      } else {
        run = 1;
      }
    }
    return best;
  }

  List<CategoryProgress> _categoryProgress({
    required List<Category> categories,
    required List<Habit> habits,
    required List<HabitCompletion> completions,
    required DateTime from,
    required DateTime to,
  }) {
    final completedKeys = <String>{}; // "habitId@yyyy-mm-dd"
    for (final c in completions) {
      if (!c.completed) continue;
      final d = TimeUtils.toDate(c.date);
      completedKeys.add('${c.habitId}@${d.toIso8601String()}');
    }

    return categories.map((cat) {
      int scheduled = 0;
      int completed = 0;
      final catHabits =
          habits.where((h) => h.categoryId == cat.id).toList();

      for (final h in catHabits) {
        var d = from;
        while (!d.isAfter(to)) {
          if (_scheduledOn(h, d)) {
            // Only count days the habit existed
            final created =
                h.createdAt != null ? TimeUtils.toDate(h.createdAt!) : null;
            if (created == null || !d.isBefore(created)) {
              scheduled++;
              if (completedKeys
                  .contains('${h.id}@${d.toIso8601String()}')) {
                completed++;
              }
            }
          }
          d = d.add(const Duration(days: 1));
        }
      }

      return CategoryProgress(
        categoryId: cat.id!,
        name: cat.name,
        icon: cat.icon,
        completed: completed,
        scheduled: scheduled,
        ratio: scheduled == 0 ? null : completed / scheduled,
      );
    }).toList();
  }

  List<ProfileInsight> _buildInsights({
    required int activityStreak,
    required List<CategoryProgress> categoryProgress,
    required List<Habit> activeHabits,
    required List<HabitCompletion> completions,
    required DateTime windowStart,
    required DateTime today,
  }) {
    // No habits at all → friendly welcome.
    if (activeHabits.isEmpty) {
      return const [WelcomeInsight()];
    }

    final picks = <ProfileInsight>[];

    // 1. Streak observation (always include if it's notable, else later)
    if (activityStreak >= 3) {
      picks.add(StreakInsight(activityStreak));
    }

    // 2. Strongest category (well above average + enough data)
    final eligible = categoryProgress
        .where((c) =>
            c.ratio != null && c.scheduled >= _minScheduledForInsight)
        .toList();
    if (eligible.isNotEmpty) {
      eligible.sort((a, b) => b.ratio!.compareTo(a.ratio!));
      final top = eligible.first;
      if (top.ratio! >= _strongRatio) {
        picks.add(StrongCategoryInsight(
            top.name, (top.ratio! * 100).round()));
      }

      // 3. Weakest category
      final bottom = eligible.last;
      if (bottom.ratio! <= _weakRatio && bottom.categoryId != top.categoryId) {
        picks.add(WeakCategoryInsight(
            bottom.name, (bottom.ratio! * 100).round()));
      }
    }

    // 4. Weekday pattern (only consider when we have ≥7 days of completions)
    final dayPattern = _weekdayPattern(completions, windowStart, today);
    if (dayPattern != null) {
      if (dayPattern.bestDay != null) {
        picks.add(StrongDayInsight(dayPattern.bestDay!));
      }
      if (dayPattern.worstDay != null &&
          dayPattern.worstDay != dayPattern.bestDay) {
        picks.add(WeakDayInsight(dayPattern.worstDay!));
      }
    }

    // 5. Trend (this week vs last week)
    final trend = _weekOverWeekTrend(completions, today);
    if (trend != null && trend.abs() >= 15) {
      picks.add(TrendInsight(trend));
    }

    // Fallback if nothing notable
    if (picks.isEmpty) {
      picks.add(activityStreak == 0
          ? const StreakInsight(0)
          : StreakInsight(activityStreak));
    }

    // Cap at 3 — minimal & non-intrusive.
    return picks.take(3).toList();
  }

  /// Returns the most-active and least-active weekday in the window,
  /// or null if the data isn't strong enough for a meaningful answer.
  _DayPattern? _weekdayPattern(
    List<HabitCompletion> completions,
    DateTime from,
    DateTime to,
  ) {
    final perDay = List<int>.filled(8, 0); // index 1..7 used
    int total = 0;
    for (final c in completions) {
      if (!c.completed) continue;
      final d = TimeUtils.toDate(c.date);
      if (d.isBefore(from) || d.isAfter(to)) continue;
      perDay[d.weekday]++;
      total++;
    }
    if (total < 7) return null; // not enough data

    int? best;
    int? worst;
    int bestCount = -1;
    int worstCount = 1 << 30;
    for (int wd = 1; wd <= 7; wd++) {
      final c = perDay[wd];
      if (c > bestCount) {
        bestCount = c;
        best = wd;
      }
      if (c < worstCount) {
        worstCount = c;
        worst = wd;
      }
    }

    // Only surface when there's a meaningful gap.
    if (bestCount - worstCount < 2) return null;
    return _DayPattern(bestDay: best, worstDay: worst);
  }

  /// Returns +N (up) or -N (down) percent, or null if not computable.
  int? _weekOverWeekTrend(
    List<HabitCompletion> completions,
    DateTime today,
  ) {
    int countIn(DateTime start, DateTime endInclusive) {
      var n = 0;
      for (final c in completions) {
        if (!c.completed) continue;
        final d = TimeUtils.toDate(c.date);
        if (!d.isBefore(start) && !d.isAfter(endInclusive)) n++;
      }
      return n;
    }

    final thisStart = today.subtract(const Duration(days: 6));
    final lastEnd = thisStart.subtract(const Duration(days: 1));
    final lastStart = lastEnd.subtract(const Duration(days: 6));

    final thisCount = countIn(thisStart, today);
    final lastCount = countIn(lastStart, lastEnd);

    if (lastCount == 0 && thisCount == 0) return null;
    if (lastCount == 0) return null; // can't compute %
    final delta = ((thisCount - lastCount) / lastCount * 100).round();
    return delta;
  }
}

class _DayPattern {
  final int? bestDay;
  final int? worstDay;
  _DayPattern({this.bestDay, this.worstDay});
}
