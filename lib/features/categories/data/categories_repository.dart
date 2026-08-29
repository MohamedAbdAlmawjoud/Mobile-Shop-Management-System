import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/database_service.dart';
import '../models/category_model.dart';

/// All SQL for categories lives here. Nothing above this layer
/// (providers, widgets) should know about table names or SQL.
class CategoriesRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  Future<List<CategoryModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<CategoryModel> insert(CategoryModel category) async {
    final db = await _db;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  Future<void> update(CategoryModel category) async {
    if (category.id == null) {
      throw ArgumentError('Cannot update a category with no id');
    }
    final db = await _db;
    await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Throws if the category has products (enforced by the DB's
  /// ON DELETE RESTRICT foreign key — caller should catch and show
  /// a friendly message, see categories_screen.dart).
  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> nameExists(String name, {int? excludingId}) async {
    final db = await _db;
    final rows = await db.query(
      'categories',
      where: excludingId != null ? 'name = ? AND id != ?' : 'name = ?',
      whereArgs: excludingId != null ? [name, excludingId] : [name],
    );
    return rows.isNotEmpty;
  }
}
