import 'package:sqflite/sqflite.dart';

import '../../domain/models/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/utils/time_utils.dart';
import '../db/app_database.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  @override
  Future<List<Category>> getAllCategories() async {
    final db = await AppDatabase.instance.database;
    final maps = await db.query('categories', orderBy: 'sort_order ASC, id ASC');
    return maps.map(Category.fromMap).toList();
  }

  @override
  Future<Category> insertCategory(Category category) async {
    final db = await AppDatabase.instance.database;
    final now = TimeUtils.now();

    // Place new category at the end
    final maxOrder = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COALESCE(MAX(sort_order), 0) FROM categories')) ??
        0;

    final toInsert = category.copyWith(
      sortOrder: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );
    final id = await db.insert('categories', toInsert.toMap());
    return toInsert.copyWith(id: id);
  }

  @override
  Future<void> updateCategory(Category category) async {
    final db = await AppDatabase.instance.database;
    final now = TimeUtils.now();
    final toUpdate = category.copyWith(updatedAt: now);
    await db.update(
      'categories',
      toUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<bool> isCategoryInUse(int categoryId) async {
    final db = await AppDatabase.instance.database;
    final count = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM habits WHERE category_id = ? AND is_archived = 0',
        [categoryId]));
    return (count ?? 0) > 0;
  }

  @override
  Future<void> reorder(List<int> orderedIds) async {
    final db = await AppDatabase.instance.database;
    final batch = db.batch();
    for (int i = 0; i < orderedIds.length; i++) {
      batch.update(
        'categories',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [orderedIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }
}
