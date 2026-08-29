import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import 'categories_repository.dart';

final categoriesRepositoryProvider = Provider((ref) => CategoriesRepository());

/// Thrown when trying to save a duplicate category name, or delete a
/// category that still has products. UI catches this and shows a message.
class CategoryOperationException implements Exception {
  final String message;
  const CategoryOperationException(this.message);
}

class CategoriesNotifier extends AsyncNotifier<List<CategoryModel>> {
  CategoriesRepository get _repo => ref.read(categoriesRepositoryProvider);

  @override
  Future<List<CategoryModel>> build() async {
    return _repo.getAll();
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const CategoryOperationException('Category name cannot be empty.');
    }
    if (await _repo.nameExists(trimmed)) {
      throw const CategoryOperationException('A category with this name already exists.');
    }
    await _repo.insert(CategoryModel(name: trimmed));
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateCategory(CategoryModel category, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      throw const CategoryOperationException('Category name cannot be empty.');
    }
    if (await _repo.nameExists(trimmed, excludingId: category.id)) {
      throw const CategoryOperationException('A category with this name already exists.');
    }
    await _repo.update(category.copyWith(name: trimmed));
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _repo.delete(id);
      ref.invalidateSelf();
      await future;
    } on Exception catch (e) {
      // sqflite throws DatabaseException wrapping the SQLite FK error text
      // when ON DELETE RESTRICT blocks the delete.
      if (e.toString().toLowerCase().contains('foreign key')) {
        throw const CategoryOperationException(
          'Cannot delete this category — it still has products assigned to it.',
        );
      }
      rethrow;
    }
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<CategoryModel>>(
  CategoriesNotifier.new,
);
