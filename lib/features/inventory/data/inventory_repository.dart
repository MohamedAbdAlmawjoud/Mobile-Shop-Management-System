import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_shop_management_system/core/constants/app_constants.dart';
import 'package:mobile_shop_management_system/core/database/database_service.dart';
import 'package:mobile_shop_management_system/features/products/models/product_model.dart';
import 'stock_movement_view.dart';

class InventoryRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  Future<List<ProductModel>> getAllProducts() async {
    final db = await _db;
    final rows = await db.query('products', orderBy: 'name ASC');
    return rows.map(ProductModel.fromMap).toList();
  }

  /// Adds stock: increments the product's quantity and records a STOCK_IN
  /// movement, in one transaction so they can't get out of sync.
  Future<void> stockIn({
    required int productId,
    required int quantity,
    required int userId,
    String? reason,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Stock-in quantity must be positive.');
    }
    final db = await _db;

    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE products SET quantity = quantity + ? WHERE id = ?',
        [quantity, productId],
      );
      await txn.insert('stock_movements', {
        'product_id': productId,
        'user_id': userId,
        'type': AppConstants.movementStockIn,
        'quantity_change': quantity,
        'reason': reason,
      });
    });
  }

  /// Movement history, most recent first, joined with product name and
  /// the user who made the change. Optionally filtered to one product.
  Future<List<StockMovementView>> getMovementHistory({int? productId, int limit = 100}) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        stock_movements.id,
        stock_movements.type,
        stock_movements.quantity_change,
        stock_movements.reason,
        stock_movements.created_at,
        products.name as product_name,
        users.username
      FROM stock_movements
      JOIN products ON products.id = stock_movements.product_id
      JOIN users ON users.id = stock_movements.user_id
      ${productId != null ? 'WHERE stock_movements.product_id = ?' : ''}
      ORDER BY stock_movements.created_at DESC
      LIMIT ?
    ''', productId != null ? [productId, limit] : [limit]);

    return rows.map(StockMovementView.fromMap).toList();
  }
}
