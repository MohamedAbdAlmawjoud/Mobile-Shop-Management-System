import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/database_service.dart';
import '../models/product_model.dart';

class ProductsRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  /// Single method backing the products list — handles optional name/barcode
  /// search and optional category filter, all in one query so the UI can
  /// combine them freely (e.g. search "phone" within "Electronics").
  Future<List<ProductModel>> search({
    String? query,
    int? categoryId,
  }) async {
    final db = await _db;

    final where = <String>[];
    final whereArgs = <Object?>[];

    if (query != null && query.trim().isNotEmpty) {
      where.add('(name LIKE ? OR barcode LIKE ?)');
      final pattern = '%${query.trim()}%';
      whereArgs.addAll([pattern, pattern]);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      whereArgs.add(categoryId);
    }

    final rows = await db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'name ASC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> getByBarcode(String barcode) async {
    final db = await _db;
    final rows = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  Future<ProductModel> insert(ProductModel product) async {
    final db = await _db;
    final id = await db.insert('products', product.toMap());
    return product.copyWith(id: id);
  }

  Future<void> update(ProductModel product) async {
    if (product.id == null) {
      throw ArgumentError('Cannot update a product with no id');
    }
    final db = await _db;
    await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> barcodeExists(String barcode, {int? excludingId}) async {
    if (barcode.isEmpty) return false;
    final db = await _db;
    final rows = await db.query(
      'products',
      where: excludingId != null ? 'barcode = ? AND id != ?' : 'barcode = ?',
      whereArgs: excludingId != null ? [barcode, excludingId] : [barcode],
    );
    return rows.isNotEmpty;
  }
}
