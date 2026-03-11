import '../models/entities/habit.dart';

abstract class HabitRepository {
  Future<List<Habit>> getAllHabits();
  Future<Habit> insertHabit(Habit habit);
  Future<void> updateHabit(Habit habit);
  Future<void> deleteHabit(int id);
}
