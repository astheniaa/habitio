import '../../domain/models/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../domain/utils/time_utils.dart';
import '../db/app_database.dart';

class HabitRepositoryImpl implements HabitRepository {
  @override
  Future<List<Habit>> getAllHabits() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('habits');
    return maps.map(Habit.fromMap).toList();
  }

  @override
  Future<Habit> insertHabit(Habit habit) async {
    final db = await AppDatabase.instance.database;
    final now = TimeUtils.nowUtc3();
    final toInsert = habit.copyWith(createdAt: now, updatedAt: now);
    final id = await db.insert('habits', toInsert.toMap());
    return toInsert.copyWith(id: id);
  }

  @override
  Future<void> updateHabit(Habit habit) async {
    final db = await AppDatabase.instance.database;
    final now = TimeUtils.nowUtc3();
    final toUpdate = habit.copyWith(updatedAt: now);
    await db.update(
      'habits',
      toUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  @override
  Future<void> deleteHabit(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }
}
