import '../../domain/models/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../db/app_database.dart';

class UserRepositoryImpl implements UserRepository {
  @override
  Future<User> getOrCreateDefaultUser() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [1]);

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }

    final defaultUser = User.defaultUser;
    await db.insert('users', defaultUser.toMap());
    return defaultUser;
  }

  @override
  Future<void> updateUser(User user) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }
}
