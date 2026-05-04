import '../models/entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getAllCategories();
  Future<Category> insertCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(int id);

  /// Returns true if any non-archived habit references this category.
  Future<bool> isCategoryInUse(int categoryId);

  /// Reorder categories. [orderedIds] is the new sort order, top → bottom.
  Future<void> reorder(List<int> orderedIds);
}
