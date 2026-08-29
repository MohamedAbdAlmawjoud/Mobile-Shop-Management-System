import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import 'cart_item.dart';

class InsufficientStockException implements Exception {
  final String message;
  const InsufficientStockException(this.message);
}

class SalesRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  /// Completes a sale: inserts the sale, its line items, decrements product
  /// stock, and records a SALE stock movement per line — all inside a single
  /// database transaction. If anything fails (including a stock check),
  /// the whole transaction rolls back and nothing is written.
  ///
  /// Returns the new sale's id.
  Future<int> completeSale({
    required List<CartItem> items,
    required String paymentMethod,
    required int userId,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Cannot complete a sale with an empty cart.');
    }

    final db = await _db;
    final total = items.fold(0.0, (sum, item) => sum + item.subtotal);

    return db.transaction<int>((txn) async {
      // Re-check stock inside the transaction — the cart's cached product
      // data could be stale if stock changed elsewhere since the cart was
      // built. This is the real guard against overselling, not the UI check
      // in CartNotifier (that one's just for responsiveness).
      for (final item in items) {
        final rows = await txn.query(
          'products',
          columns: ['quantity', 'name'],
          where: 'id = ?',
          whereArgs: [item.product.id],
        );
        if (rows.isEmpty) {
          throw InsufficientStockException('${item.product.name} no longer exists.');
        }
        final currentQuantity = rows.first['quantity'] as int;
        if (currentQuantity < item.quantity) {
          throw InsufficientStockException(
            'Not enough stock for ${item.product.name} — only $currentQuantity left.',
          );
        }
      }

      // Insert the sale.
      final saleId = await txn.insert('sales', {
        'user_id': userId,
        'total': total,
        'payment_method': paymentMethod,
      });

      // Insert line items, decrement stock, record stock movements.
      for (final item in items) {
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'unit_price': item.product.price,
        });

        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.product.id],
        );

        await txn.insert('stock_movements', {
          'product_id': item.product.id,
          'user_id': userId,
          'type': AppConstants.movementSale,
          'quantity_change': -item.quantity,
          'reason': 'Sale #$saleId',
        });
      }

      return saleId;
    });
  }
}
