import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../../domain/models/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryViewModel extends ChangeNotifier {
  final CategoryRepository _repo;

  List<Category> _categories = [];
  bool _isLoading = false;

  CategoryViewModel({required CategoryRepository repository}) : _repo = repository;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Category? byId(int id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await _repo.getAllCategories();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Category> add({required String name, required String icon}) async {
    final created = await _repo.insertCategory(
        Category(name: name.trim(), icon: icon));
    _categories = [..._categories, created];
    notifyListeners();
    return created;
  }

  Future<void> rename(Category cat, String newName, String newIcon) async {
    final updated = cat.copyWith(name: newName.trim(), icon: newIcon);
    await _repo.updateCategory(updated);
    final idx = _categories.indexWhere((c) => c.id == cat.id);
    if (idx != -1) {
      final list = List<Category>.from(_categories);
      list[idx] = updated;
      _categories = list;
      notifyListeners();
    }
  }

  /// Deletes the category. Returns true on success; false if it's still in
  /// use by any habit.
  Future<bool> delete(int id) async {
    final inUse = await _repo.isCategoryInUse(id);
    if (inUse) return false;
    await _repo.deleteCategory(id);
    _categories = _categories.where((c) => c.id != id).toList();
    notifyListeners();
    return true;
  }

  Future<void> reorder(List<Category> newOrder) async {
    _categories = newOrder;
    notifyListeners();
    await _repo.reorder(newOrder.map((c) => c.id!).toList());
  }
}
