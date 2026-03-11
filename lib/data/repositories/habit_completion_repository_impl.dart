import '../../domain/models/entities/habit_completion.dart';
import '../../domain/repositories/habit_completion_repository.dart';
import '../../domain/utils/time_utils.dart';
import '../db/app_database.dart';

class HabitCompletionRepositoryImpl implements HabitCompletionRepository {
  @override
  Future<List<HabitCompletion>> getAllCompletions() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('habit_completions');
    return maps.map(HabitCompletion.fromMap).toList();
  }

  @override
  Future<void> insertCompletion(HabitCompletion completion) async {
    final db = await AppDatabase.instance.database;
    await db.insert('habit_completions', completion.toMap());
  }

  @override
  Future<void> deleteCompletion(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('habit_completions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteCompletionByHabitAndDate(
      int habitId, DateTime date) async {
    final db = await AppDatabase.instance.database;
    final normalizedDate = TimeUtils.toUtc3Date(date);

    // Query all completions for this habit and find the one matching the date
    final maps = await db.query(
      'habit_completions',
      where: 'habit_id = ?',
      whereArgs: [habitId],
    );

    for (final map in maps) {
      final completion = HabitCompletion.fromMap(map);
      if (TimeUtils.isSameUtc3Date(completion.date, normalizedDate)) {
        await db.delete(
          'habit_completions',
          where: 'id = ?',
          whereArgs: [completion.id],
        );
      }
    }
  }
}
