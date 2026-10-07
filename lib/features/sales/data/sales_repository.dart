import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import 'cart_item.dart';
import 'sale_detail.dart';

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

    // Validate the quantities per product, since a cart may contain more
    // than one line for the same non-serialized product.
    final quantitiesByProduct = <int, int>{};
    final seenImeis = <String>{};
    for (final item in items) {
      if (item.isImeiUnit) {
        if (!seenImeis.add(item.imei!)) {
          throw InsufficientStockException(
            'IMEI ${item.imei} appears more than once in the cart.',
          );
        }
      } else {
        quantitiesByProduct.update(
          item.product.id!,
          (quantity) => quantity + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }
    }

    return db.transaction<int>((txn) async {
      // Re-check stock inside the transaction — the cart's cached product
      // data could be stale if stock changed elsewhere since the cart was
      // built. This is the real guard against overselling, not the UI check
      // in CartNotifier (that one's just for responsiveness).
      for (final item in items.where((item) => item.isImeiUnit)) {
        // For an IMEI unit, "stock" means this exact serial is still
        // in_stock — someone else could have sold it since it was added
        // to this cart.
        final rows = await txn.query(
          'product_imeis',
          where: 'imei = ? AND product_id = ?',
          whereArgs: [item.imei, item.product.id],
        );
        if (rows.isEmpty || rows.first['status'] != 'in_stock') {
          throw InsufficientStockException(
            '${item.product.name} (IMEI ${item.imei}) is no longer available.',
          );
        }
      }
      for (final entry in quantitiesByProduct.entries) {
        final rows = await txn.query(
          'products',
          columns: ['quantity', 'name'],
          where: 'id = ?',
          whereArgs: [entry.key],
        );
        if (rows.isEmpty) {
          throw InsufficientStockException(
            'Product ${entry.key} no longer exists.',
          );
        }
        final currentQuantity = rows.first['quantity'] as int;
        if (currentQuantity < entry.value) {
          throw InsufficientStockException(
            'Not enough stock for ${rows.first['name']} — only $currentQuantity left.',
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

        if (item.isImeiUnit) {
          await txn.update(
            'product_imeis',
            {'status': 'sold', 'sale_id': saleId},
            where: 'imei = ?',
            whereArgs: [item.imei],
          );
        }

        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.product.id],
        );

        await txn.insert('stock_movements', {
          'product_id': item.product.id,
          'user_id': userId,
          'type': AppConstants.movementSale,
          'quantity_change': -item.quantity,
          'reason': item.isImeiUnit
              ? 'Sale #$saleId (IMEI ${item.imei})'
              : 'Sale #$saleId',
        });
      }

      return saleId;
    });
  }

  /// Full detail for one sale (header + line items), for rendering an
  /// invoice. Returns null if the sale doesn't exist.
  Future<SaleDetail?> getSaleDetail(int saleId) async {
    final db = await _db;

    final saleRows = await db.rawQuery(
      '''
      SELECT sales.id, sales.total, sales.payment_method, sales.created_at, users.username
      FROM sales
      JOIN users ON users.id = sales.user_id
      WHERE sales.id = ?
    ''',
      [saleId],
    );

    if (saleRows.isEmpty) return null;
    final saleRow = saleRows.first;

    final itemRows = await db.rawQuery(
      '''
      SELECT sale_items.quantity, sale_items.unit_price, products.name as product_name
      FROM sale_items
      JOIN products ON products.id = sale_items.product_id
      WHERE sale_items.sale_id = ?
    ''',
      [saleId],
    );

    final items = itemRows
        .map(
          (r) => SaleDetailItem(
            productName: r['product_name'] as String,
            quantity: r['quantity'] as int,
            unitPrice: (r['unit_price'] as num).toDouble(),
          ),
        )
        .toList();

    return SaleDetail(
      saleId: saleRow['id'] as int,
      createdAt: DateTime.parse(saleRow['created_at'] as String),
      cashierUsername: saleRow['username'] as String,
      paymentMethod: saleRow['payment_method'] as String,
      total: (saleRow['total'] as num).toDouble(),
      items: items,
    );
  }
}
