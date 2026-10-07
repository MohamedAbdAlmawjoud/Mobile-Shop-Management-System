import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_shop_management_system/core/constants/app_constants.dart';
import 'package:mobile_shop_management_system/core/database/database_service.dart';
import 'product_imei.dart';

class ImeiOperationException implements Exception {
  final String message;
  const ImeiOperationException(this.message);
}

class ImeiRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  /// All in-stock IMEIs for a product, for the sales picker.
  Future<List<ProductImei>> getInStock(int productId) async {
    final db = await _db;
    final rows = await db.query(
      'product_imeis',
      where: 'product_id = ? AND status = ?',
      whereArgs: [productId, 'in_stock'],
      orderBy: 'created_at ASC',
    );
    return rows.map(ProductImei.fromMap).toList();
  }

  /// All IMEIs (in stock or sold) for a product, for the admin "View IMEIs" list.
  Future<List<ProductImei>> getAllForProduct(int productId) async {
    final db = await _db;
    final rows = await db.query(
      'product_imeis',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return rows.map(ProductImei.fromMap).toList();
  }

  /// Adds a batch of new IMEIs for a product (from Stock In) and bumps the
  /// product's quantity to match, in one transaction. Also records a
  /// STOCK_IN movement, same as a normal (non-IMEI) stock-in.
  Future<void> stockInImeis({
    required int productId,
    required List<String> imeis,
    required int userId,
    String? reason,
  }) async {
    if (imeis.isEmpty) {
      throw const ImeiOperationException('Enter at least one IMEI.');
    }
    final trimmed = imeis.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final unique = trimmed.toSet();
    if (unique.length != trimmed.length) {
      throw const ImeiOperationException('Duplicate IMEI entered in this batch.');
    }

    final db = await _db;

    // Pre-check against existing IMEIs for a friendlier error than a raw
    // UNIQUE constraint failure (which would abort the whole transaction).
    for (final imei in trimmed) {
      final existing = await db.query('product_imeis', where: 'imei = ?', whereArgs: [imei]);
      if (existing.isNotEmpty) {
        throw ImeiOperationException('IMEI "$imei" already exists in the system.');
      }
    }

    await db.transaction((txn) async {
      for (final imei in trimmed) {
        await txn.insert('product_imeis', {
          'product_id': productId,
          'imei': imei,
          'status': 'in_stock',
        });
      }
      await txn.rawUpdate(
        'UPDATE products SET quantity = quantity + ? WHERE id = ?',
        [trimmed.length, productId],
      );
      await txn.insert('stock_movements', {
        'product_id': productId,
        'user_id': userId,
        'type': AppConstants.movementStockIn,
        'quantity_change': trimmed.length,
        'reason': reason ?? 'Stock in (${trimmed.length} IMEI unit(s))',
      });
    });
  }

  /// Removes an unsold IMEI entered by mistake (e.g. typo). Cannot remove
  /// a sold one — that's permanent sale history.
  Future<void> removeUnsold(int imeiRowId, {required int userId}) async {
    final db = await _db;

    await db.transaction((txn) async {
      final rows = await txn.query('product_imeis', where: 'id = ?', whereArgs: [imeiRowId]);
      if (rows.isEmpty) {
        throw const ImeiOperationException('IMEI record not found.');
      }
      final row = rows.first;
      if (row['status'] != 'in_stock') {
        throw const ImeiOperationException('Cannot remove an IMEI that has already been sold.');
      }
      final productId = row['product_id'] as int;

      await txn.delete('product_imeis', where: 'id = ?', whereArgs: [imeiRowId]);
      await txn.rawUpdate(
        'UPDATE products SET quantity = quantity - 1 WHERE id = ?',
        [productId],
      );
      await txn.insert('stock_movements', {
        'product_id': productId,
        'user_id': userId,
        'type': AppConstants.movementAdjustment,
        'quantity_change': -1,
        'reason': 'Removed incorrectly entered IMEI',
      });
    });
  }

  /// Looks up a single IMEI anywhere in the system — which product it is,
  /// and if sold, when and by whom. Used for warranty/support lookups.
  Future<ImeiLookupResult?> lookup(String imei) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        product_imeis.*,
        products.name as product_name,
        sales.created_at as sold_at,
        users.username as sold_by_username
      FROM product_imeis
      JOIN products ON products.id = product_imeis.product_id
      LEFT JOIN sales ON sales.id = product_imeis.sale_id
      LEFT JOIN users ON users.id = sales.user_id
      WHERE product_imeis.imei = ?
    ''', [imei.trim()]);

    if (rows.isEmpty) return null;
    final row = rows.first;

    return ImeiLookupResult(
      imei: ProductImei.fromMap(row),
      productName: row['product_name'] as String,
      soldAt: row['sold_at'] != null ? DateTime.parse(row['sold_at'] as String) : null,
      soldByUsername: row['sold_by_username'] as String?,
    );
  }
}
