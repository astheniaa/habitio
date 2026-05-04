import '../models/entities/habit_completion.dart';

abstract class HabitCompletionRepository {
  Future<List<HabitCompletion>> getAllCompletions();
  Future<void> insertCompletion(HabitCompletion completion);

  /// Updates an existing completion row (matched by id).
  Future<void> updateCompletion(HabitCompletion completion);

  Future<void> deleteCompletion(int id);
  Future<void> deleteCompletionByHabitAndDate(int habitId, DateTime date);
}
