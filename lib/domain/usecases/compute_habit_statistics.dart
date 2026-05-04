import '../models/entities/habit.dart';
import '../models/entities/habit_completion.dart';
import '../models/habit_statistics.dart';
import '../utils/time_utils.dart';

class ComputeHabitStatisticsUseCase {
  /// Compute statistics for a single [habit] given all its [completions].
  /// [period] controls which date range is used for completion % and totals.
  /// Streaks and consolidation are always computed over all time.
  HabitStatistics call(
    Habit habit,
    List<HabitCompletion> allCompletions,
    StatsPeriod period,
  ) {
    final now = TimeUtils.now();
    final today = TimeUtils.toDate(now);

    // Filter completions for this habit only
    final completions =
        allCompletions.where((c) => c.habitId == habit.id).toList();

    // Build set of completed dates for O(1) lookup
    final completedDates = <DateTime>{};
    for (final c in completions) {
      completedDates.add(TimeUtils.toDate(c.date));
    }

    // All-time scheduled dates (from creation to today)
    final creationDate = habit.createdAt != null
        ? TimeUtils.toDate(habit.createdAt!)
        : (completions.isNotEmpty
            ? completions
                .map((c) => TimeUtils.toDate(c.date))
                .reduce((a, b) => a.isBefore(b) ? a : b)
            : today);

    final allScheduled = _scheduledDates(habit, creationDate, today);

    // Period-scoped scheduled dates
    final periodStart = _periodStart(period, today, creationDate);
    final periodScheduled = _scheduledDates(habit, periodStart, today);
    final periodCompletions =
        periodScheduled.where((d) => completedDates.contains(d)).length;
    final pct =
        periodScheduled.isEmpty ? 0.0 : periodCompletions / periodScheduled.length;

    // Streaks (all-time)
    final streaks = _computeStreaks(allScheduled, completedDates, today);

    // Consolidation (all-time)
    final consolidation = _computeConsolidation(allScheduled, completedDates);

    return HabitStatistics(
      habitId: habit.id!,
      currentStreak: streaks.current,
      bestStreak: streaks.best,
      completionPercentage: pct,
      consolidationProgress: consolidation.progress,
      isConsolidated: consolidation.isConsolidated,
      postConsolidationStreak: consolidation.postStreak,
      freezeActive: consolidation.freezeActive,
      totalCompletions: periodCompletions,
      totalScheduledDays: periodScheduled.length,
    );
  }

  /// Compute overall statistics across all habits.
  OverallStatistics computeOverall(
    List<Habit> habits,
    List<HabitCompletion> completions,
    StatsPeriod period,
  ) {
    final now = TimeUtils.now();
    final today = TimeUtils.toDate(now);
    final active = habits.where((h) => !h.isArchived).toList();

    // Total completions in period
    final periodStart = _periodStart(
      period,
      today,
      active.isEmpty ? today : _earliestCreation(active),
    );
    final periodCompletions = completions.where((c) {
      final d = TimeUtils.toDate(c.date);
      return !d.isBefore(periodStart) && !d.isAfter(today);
    }).length;

    // Activity streak: consecutive calendar days with ≥1 completion
    final activityStreak = _computeActivityStreak(completions, today);

    // Best individual habit streak
    int bestStreak = 0;
    String? bestName;
    for (final h in active) {
      final stats = call(h, completions, StatsPeriod.allTime);
      if (stats.bestStreak > bestStreak) {
        bestStreak = stats.bestStreak;
        bestName = h.title;
      }
    }

    return OverallStatistics(
      totalCompletionsInPeriod: periodCompletions,
      activityStreak: activityStreak,
      bestHabitStreak: bestStreak,
      bestHabitStreakName: bestName,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  DateTime _periodStart(
      StatsPeriod period, DateTime today, DateTime earliest) {
    switch (period) {
      case StatsPeriod.week:
        return TimeUtils.weekStart(today);
      case StatsPeriod.month:
        return DateTime(today.year, today.month, 1);
      case StatsPeriod.allTime:
        return earliest;
    }
  }

  DateTime _earliestCreation(List<Habit> habits) {
    DateTime earliest = TimeUtils.now();
    for (final h in habits) {
      if (h.createdAt != null) {
        final d = TimeUtils.toDate(h.createdAt!);
        if (d.isBefore(earliest)) earliest = d;
      }
    }
    return earliest;
  }

  /// Returns all dates between [from] and [to] (inclusive) when [habit] is
  /// scheduled.
  List<DateTime> _scheduledDates(Habit habit, DateTime from, DateTime to) {
    final dates = <DateTime>[];
    var d = from;
    while (!d.isAfter(to)) {
      if (_isScheduled(habit, d)) dates.add(d);
      d = d.add(const Duration(days: 1));
    }
    return dates;
  }

  bool _isScheduled(Habit habit, DateTime date) {
    if (habit.scheduleType == HabitScheduleType.everyday) return true;
    return habit.weekdays.contains(date.weekday);
  }

  // ── Streak calculation ───────────────────────────────────────────────────

  _StreakResult _computeStreaks(
    List<DateTime> scheduledDates,
    Set<DateTime> completedDates,
    DateTime today,
  ) {
    if (scheduledDates.isEmpty) {
      return const _StreakResult(current: 0, best: 0);
    }

    // Current streak: walk backwards from the most recent scheduled date
    int current = 0;
    for (int i = scheduledDates.length - 1; i >= 0; i--) {
      final d = scheduledDates[i];
      // Skip today if not yet completed (day is still in progress)
      if (d == today && !completedDates.contains(d)) continue;
      if (completedDates.contains(d)) {
        current++;
      } else {
        break;
      }
    }

    // Best streak: walk forward
    int best = 0;
    int running = 0;
    for (final d in scheduledDates) {
      if (completedDates.contains(d)) {
        running++;
        if (running > best) best = running;
      } else {
        running = 0;
      }
    }

    return _StreakResult(current: current, best: best);
  }

  // ── Consolidation calculation ────────────────────────────────────────────

  _ConsolidationResult _computeConsolidation(
    List<DateTime> scheduledDates,
    Set<DateTime> completedDates,
  ) {
    int progress = 0;
    bool freezeActive = false;
    bool isConsolidated = false;
    int postStreak = 0;

    for (final d in scheduledDates) {
      final completed = completedDates.contains(d);

      if (!isConsolidated) {
        // Pre-consolidation: building progress 0→21
        if (completed) {
          freezeActive = false;
          progress++;
          if (progress >= 21) {
            isConsolidated = true;
            postStreak = 0;
          }
        } else {
          if (!freezeActive) {
            freezeActive = true; // first miss → freeze
          } else {
            progress = 0; // second consecutive miss → reset
            freezeActive = false;
          }
        }
      } else {
        // Post-consolidation: infinite counter with same freeze logic
        if (completed) {
          freezeActive = false;
          postStreak++;
        } else {
          if (!freezeActive) {
            freezeActive = true;
          } else {
            postStreak = 0;
            freezeActive = false;
          }
        }
      }
    }

    return _ConsolidationResult(
      progress: progress,
      isConsolidated: isConsolidated,
      postStreak: postStreak,
      freezeActive: freezeActive,
    );
  }

  // ── Activity streak ──────────────────────────────────────────────────────

  int _computeActivityStreak(
    List<HabitCompletion> completions,
    DateTime today,
  ) {
    final completedDays = <DateTime>{};
    for (final c in completions) {
      completedDays.add(TimeUtils.toDate(c.date));
    }

    int streak = 0;
    var d = today;
    // If today has no completion yet, start from yesterday
    if (!completedDays.contains(d)) {
      d = d.subtract(const Duration(days: 1));
    }
    while (completedDays.contains(d)) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Check if the consolidation just reached 21 for the given habit.
  /// Used by ViewModel to award one-time bonus.
  bool isJustConsolidated(
    Habit habit,
    List<HabitCompletion> completions,
  ) {
    final now = TimeUtils.now();
    final today = TimeUtils.toDate(now);
    final creationDate = habit.createdAt != null
        ? TimeUtils.toDate(habit.createdAt!)
        : today;
    final scheduled = _scheduledDates(habit, creationDate, today);
    final completedDates = <DateTime>{};
    for (final c in completions.where((c) => c.habitId == habit.id)) {
      completedDates.add(TimeUtils.toDate(c.date));
    }
    final result = _computeConsolidation(scheduled, completedDates);
    return result.isConsolidated;
  }

  /// Get the map of date → completed for contribution grid.
  Map<DateTime, bool> completionMap(
    Habit habit,
    List<HabitCompletion> completions,
    StatsPeriod period,
  ) {
    final now = TimeUtils.now();
    final today = TimeUtils.toDate(now);
    final creationDate = habit.createdAt != null
        ? TimeUtils.toDate(habit.createdAt!)
        : today;
    final periodStart = _periodStart(period, today, creationDate);

    final completedDates = <DateTime>{};
    for (final c in completions.where((c) => c.habitId == habit.id)) {
      completedDates.add(TimeUtils.toDate(c.date));
    }

    final map = <DateTime, bool>{};
    var d = periodStart;
    while (!d.isAfter(today)) {
      if (_isScheduled(habit, d)) {
        map[d] = completedDates.contains(d);
      }
      d = d.add(const Duration(days: 1));
    }
    return map;
  }

  /// Whether yesterday had any missed scheduled habit (for ice overlay).
  bool hadMissYesterday(List<Habit> habits, List<HabitCompletion> completions) {
    final now = TimeUtils.now();
    final yesterday = TimeUtils.toDate(now).subtract(const Duration(days: 1));

    final completedYesterday = <int>{};
    for (final c in completions) {
      if (TimeUtils.isSameDate(c.date, yesterday)) {
        completedYesterday.add(c.habitId);
      }
    }

    for (final h in habits) {
      if (h.isArchived) continue;
      if (!_isScheduled(h, yesterday)) continue;
      // Check habit existed by yesterday
      if (h.createdAt != null &&
          TimeUtils.toDate(h.createdAt!).isAfter(yesterday)) {
        continue;
      }
      if (!completedYesterday.contains(h.id)) return true;
    }
    return false;
  }

  /// Whether any habit was completed today (to dismiss ice).
  bool hasCompletionToday(List<HabitCompletion> completions) {
    final now = TimeUtils.now();
    final today = TimeUtils.toDate(now);
    return completions.any((c) => TimeUtils.isSameDate(c.date, today));
  }
}

class _StreakResult {
  final int current;
  final int best;
  const _StreakResult({required this.current, required this.best});
}

class _ConsolidationResult {
  final int progress;
  final bool isConsolidated;
  final int postStreak;
  final bool freezeActive;
  const _ConsolidationResult({
    required this.progress,
    required this.isConsolidated,
    required this.postStreak,
    required this.freezeActive,
  });
}
