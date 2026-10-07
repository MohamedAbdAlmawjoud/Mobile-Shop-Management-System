import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_service.dart';
import 'purchase_cart_item.dart';
import 'purchase_models.dart';

class PurchaseException implements Exception {
  final String message;
  const PurchaseException(this.message);
}

class PurchasesRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  /// Completes a purchase: inserts the purchase, its line items, increments
  /// product stock (and, for IMEI lines, records each individual unit),
  /// and logs a stock movement per line — all in one transaction.
  ///
  /// Note: stock movements from a purchase are recorded with type STOCK_IN
  /// (not a separate PURCHASE type) — the reason field notes the supplier
  /// and purchase number instead. Movement history and reports already
  /// read STOCK_IN as "stock coming in," so this keeps that logic simple
  /// rather than requiring a schema change to the movement type constraint.
  ///
  /// Returns the new purchase's id.
  Future<int> completePurchase({
    required int supplierId,
    required List<PurchaseCartItem> items,
    required int userId,
    String? notes,
  }) async {
    if (items.isEmpty) {
      throw const PurchaseException(
        'Cannot complete a purchase with no items.',
      );
    }

    final db = await _db;
    for (final item in items) {
      if (item.imeis == null) continue;
      final unique = item.imeis!.toSet();
      if (unique.length != item.imeis!.length) {
        throw PurchaseException(
          'Duplicate IMEI entered for ${item.product.name}.',
        );
      }
    }

    final total = items.fold(0.0, (sum, item) => sum + item.subtotal);

    try {
      return await db.transaction<int>((txn) async {
        // Keep the friendly duplicate check in the transaction. The database's
        // UNIQUE constraint remains the final guard against competing writes.
        for (final item in items) {
          if (!item.isImeiLine) continue;
          for (final imei in item.imeis!) {
            final existing = await txn.query(
              'product_imeis',
              where: 'imei = ?',
              whereArgs: [imei],
            );
            if (existing.isNotEmpty) {
              throw PurchaseException(
                'IMEI "$imei" already exists in the system.',
              );
            }
          }
        }

        final purchaseId = await txn.insert('purchases', {
          'supplier_id': supplierId,
          'user_id': userId,
          'total': total,
          'notes': notes,
        });

        for (final item in items) {
          await txn.insert('purchase_items', {
            'purchase_id': purchaseId,
            'product_id': item.product.id,
            'quantity': item.quantity,
            'unit_cost': item.unitCost,
          });

          if (item.isImeiLine) {
            for (final imei in item.imeis!) {
              await txn.insert('product_imeis', {
                'product_id': item.product.id,
                'imei': imei,
                'status': 'in_stock',
              });
            }
          }

          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [item.quantity, item.product.id],
          );

          await txn.insert('stock_movements', {
            'product_id': item.product.id,
            'user_id': userId,
            'type': AppConstants.movementStockIn,
            'quantity_change': item.quantity,
            'reason': 'Purchase #$purchaseId',
          });
        }

        return purchaseId;
      });
    } catch (error) {
      if (error.toString().contains(
        'UNIQUE constraint failed: product_imeis.imei',
      )) {
        throw const PurchaseException(
          'An IMEI in this purchase already exists in the system.',
        );
      }
      rethrow;
    }
  }

  Future<List<PurchaseHistoryRow>> getHistory({int limit = 200}) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT
        purchases.id,
        purchases.total,
        purchases.created_at,
        suppliers.name as supplier_name,
        users.username,
        (SELECT COALESCE(SUM(purchase_items.quantity), 0) FROM purchase_items WHERE purchase_items.purchase_id = purchases.id) as item_count
      FROM purchases
      JOIN suppliers ON suppliers.id = purchases.supplier_id
      JOIN users ON users.id = purchases.user_id
      ORDER BY purchases.created_at DESC
      LIMIT ?
    ''',
      [limit],
    );

    return rows
        .map(
          (r) => PurchaseHistoryRow(
            purchaseId: r['id'] as int,
            createdAt: DateTime.parse(r['created_at'] as String),
            supplierName: r['supplier_name'] as String,
            username: r['username'] as String,
            total: (r['total'] as num).toDouble(),
            itemCount: r['item_count'] as int,
          ),
        )
        .toList();
  }

  Future<PurchaseDetail?> getDetail(int purchaseId) async {
    final db = await _db;

    final purchaseRows = await db.rawQuery(
      '''
      SELECT purchases.*, suppliers.name as supplier_name, users.username
      FROM purchases
      JOIN suppliers ON suppliers.id = purchases.supplier_id
      JOIN users ON users.id = purchases.user_id
      WHERE purchases.id = ?
    ''',
      [purchaseId],
    );

    if (purchaseRows.isEmpty) return null;
    final row = purchaseRows.first;

    final itemRows = await db.rawQuery(
      '''
      SELECT purchase_items.quantity, purchase_items.unit_cost, products.name as product_name
      FROM purchase_items
      JOIN products ON products.id = purchase_items.product_id
      WHERE purchase_items.purchase_id = ?
    ''',
      [purchaseId],
    );

    final items = itemRows
        .map(
          (r) => PurchaseDetailItem(
            productName: r['product_name'] as String,
            quantity: r['quantity'] as int,
            unitCost: (r['unit_cost'] as num).toDouble(),
          ),
        )
        .toList();

    return PurchaseDetail(
      purchaseId: row['id'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      supplierName: row['supplier_name'] as String,
      username: row['username'] as String,
      total: (row['total'] as num).toDouble(),
      notes: row['notes'] as String?,
      items: items,
    );
  }
}
