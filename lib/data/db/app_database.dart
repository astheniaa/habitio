import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Schema for fresh installs (v4)
  // ─────────────────────────────────────────────────────────────────────────

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
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        schedule_type INTEGER NOT NULL,
        weekdays TEXT NOT NULL DEFAULT '',
        is_archived INTEGER NOT NULL DEFAULT 0,
        consolidation_bonus_awarded INTEGER NOT NULL DEFAULT 0,
        habit_type INTEGER NOT NULL DEFAULT 0,
        target_value INTEGER NOT NULL DEFAULT 1,
        unit TEXT NOT NULL DEFAULT '',
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
        progress INTEGER NOT NULL DEFAULT 1,
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

    await _seedDefaults(db);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Migrations
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN avatar_path TEXT');
      await db.execute('ALTER TABLE users ADD COLUMN avatar_rpg_id TEXT');
    }
    if (oldVersion < 3) {
      await db.execute(
          'ALTER TABLE habits ADD COLUMN consolidation_bonus_awarded INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 4) {
      await _migrateToV4(db);
    }
  }

  /// v3 → v4: introduce `categories` table; migrate `habits.specialization`
  /// (enum index 0..4) to `habits.category_id` (1..5); add quantitative
  /// fields; add `habit_completions.progress`.
  Future<void> _migrateToV4(Database db) async {
    // 1. Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL DEFAULT '',
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // 2. Seed five categories matching the previous fixed-enum order. Their
    //    auto-increment ids will be 1..5 — used by the SELECT below.
    await _seedDefaultCategories(db);

    // 3. Rebuild the habits table — SQLite can't drop columns or change
    //    NOT NULL constraints without a table rewrite.
    await db.execute('''
      CREATE TABLE habits_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        schedule_type INTEGER NOT NULL,
        weekdays TEXT NOT NULL DEFAULT '',
        is_archived INTEGER NOT NULL DEFAULT 0,
        consolidation_bonus_awarded INTEGER NOT NULL DEFAULT 0,
        habit_type INTEGER NOT NULL DEFAULT 0,
        target_value INTEGER NOT NULL DEFAULT 1,
        unit TEXT NOT NULL DEFAULT '',
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Map specialization index (0..4) → category id (1..5)
    await db.execute('''
      INSERT INTO habits_new
        (id, title, category_id, schedule_type, weekdays,
         is_archived, consolidation_bonus_awarded,
         habit_type, target_value, unit,
         created_at, updated_at)
      SELECT
         id, title, specialization + 1, schedule_type, weekdays,
         is_archived, consolidation_bonus_awarded,
         0, 1, '',
         created_at, updated_at
        FROM habits
    ''');

    await db.execute('DROP TABLE habits');
    await db.execute('ALTER TABLE habits_new RENAME TO habits');

    // 4. Add progress column to completions
    await db.execute(
        'ALTER TABLE habit_completions ADD COLUMN progress INTEGER NOT NULL DEFAULT 1');
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Seeds
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _seedDefaults(Database db) async {
    await db.insert('users', {
      'id': 1,
      'name': _isRussian() ? 'Герой' : 'Hero',
      'level': 1,
      'current_xp': 0,
      'xp_to_next_level': 100,
    });

    await _seedDefaultCategories(db);
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final isRu = _isRussian();
    final now = DateTime.now().toIso8601String();

    const defaults = [
      // (name_ru, name_en, emoji)
      ['Спорт', 'Sport', '🏃'],
      ['Творчество', 'Creativity', '🎨'],
      ['Финансы', 'Finance', '💰'],
      ['Социализация', 'Social', '👥'],
      ['Процессинг', 'Processing', '⚙️'],
    ];

    for (int i = 0; i < defaults.length; i++) {
      final row = defaults[i];
      await db.insert('categories', {
        'name': isRu ? row[0] : row[1],
        'icon': row[2],
        'sort_order': i,
        'created_at': now,
        'updated_at': now,
      });
    }
  }

  bool _isRussian() {
    return PlatformDispatcher.instance.locale.languageCode == 'ru';
  }
}
