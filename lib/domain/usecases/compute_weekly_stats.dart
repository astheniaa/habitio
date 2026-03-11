import '../models/entities/habit.dart';
import '../models/entities/habit_completion.dart';
import '../models/weekly_stats.dart';
import '../utils/time_utils.dart';
import 'filter_habits_for_date.dart';

class ComputeWeeklyStatsUseCase {
  final FilterHabitsForDateUseCase _filterHabits;

  ComputeWeeklyStatsUseCase({FilterHabitsForDateUseCase? filterHabits})
      : _filterHabits = filterHabits ?? FilterHabitsForDateUseCase();

  WeeklyStats call(
    List<Habit> habits,
    List<HabitCompletion> completions,
    DateTime now,
  ) {
    final weekStart = TimeUtils.weekStartUtc3(now);
    final axisValues = {for (final s in HabitSpecialization.values) s: 0.0};

    for (int i = 0; i < 7; i++) {
      final dayDate = weekStart.add(Duration(days: i));
      final filteredHabits = _filterHabits(habits, dayDate);

      for (final spec in HabitSpecialization.values) {
        final scheduled =
            filteredHabits.where((h) => h.specialization == spec).toList();
        if (scheduled.isEmpty) continue;

        final completedCount = scheduled.where((habit) {
          return completions.any((c) =>
              c.habitId == habit.id &&
              c.completed &&
              TimeUtils.isSameUtc3Date(c.date, dayDate));
        }).length;

        axisValues[spec] = axisValues[spec]! + completedCount / scheduled.length;
      }
    }

    return WeeklyStats(axisValues: axisValues);
  }
}
