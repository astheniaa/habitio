import 'entities/habit.dart';

class WeeklyStats {
  final Map<HabitSpecialization, double> axisValues;

  const WeeklyStats({required this.axisValues});

  double valueFor(HabitSpecialization spec) => axisValues[spec] ?? 0.0;

  static WeeklyStats get empty => WeeklyStats(
        axisValues: {for (final s in HabitSpecialization.values) s: 0.0},
      );
}
