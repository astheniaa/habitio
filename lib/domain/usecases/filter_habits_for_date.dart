import '../models/entities/habit.dart';

class FilterHabitsForDateUseCase {
  List<Habit> call(List<Habit> habits, DateTime date) {
    return habits.where((habit) {
      if (habit.isArchived) return false;
      if (habit.scheduleType == HabitScheduleType.everyday) return true;
      return habit.weekdays.contains(date.weekday);
    }).toList();
  }
}
