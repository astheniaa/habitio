import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'habit_rpg_tracker.db');

    return await openDatabase(
      dbPath,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE users ADD COLUMN avatar_path TEXT');
      await db.execute(
          'ALTER TABLE users ADD COLUMN avatar_rpg_id TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE habits ADD COLUMN consolidation_bonus_awarded INTEGER NOT NULL DEFAULT 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        level INTEGER NOT NULL,
        current_xp INTEGER NOT NULL,
        xp_to_next_level INTEGER NOT NULL,
        avatar_path TEXT,
        avatar_rpg_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        specialization INTEGER NOT NULL,
        schedule_type INTEGER NOT NULL,
        weekdays TEXT NOT NULL DEFAULT '',
        is_archived INTEGER NOT NULL DEFAULT 0,
        consolidation_bonus_awarded INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_completions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habit_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        completed INTEGER NOT NULL,
        FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bosses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        max_hp INTEGER NOT NULL,
        current_hp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE quests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        target_type TEXT NOT NULL,
        linked_habit_id INTEGER,
        progress INTEGER NOT NULL,
        target_value INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert default user
    await db.insert('users', {
      'id': 1,
      'name': 'Герой',
      'level': 1,
      'current_xp': 0,
      'xp_to_next_level': 100,
    });
  }
}
