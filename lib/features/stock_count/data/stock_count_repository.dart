import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_shop_management_system/core/constants/app_constants.dart';
import 'package:mobile_shop_management_system/core/database/database_service.dart';

class StockCountRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  /// Applies one approved stock count adjustment: sets the product's
  /// quantity to the actual counted value and records an ADJUSTMENT
  /// movement with the difference, user, and reason — in one transaction.
  Future<void> applyAdjustment({
    required int productId,
    required int actualQuantity,
    required int difference,
    required int userId,
    String? reason,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      await txn.update(
        'products',
        {'quantity': actualQuantity},
        where: 'id = ?',
        whereArgs: [productId],
      );
      await txn.insert('stock_movements', {
        'product_id': productId,
        'user_id': userId,
        'type': AppConstants.movementAdjustment,
        'quantity_change': difference,
        'reason': reason ?? 'Stock count adjustment',
      });
    });
  }

  /// Applies a whole batch of adjustments as one transaction — either all
  /// succeed together or none do, matching how a stock count session is
  /// approved as a single unit of work.
  Future<void> applyBatch({
    required List<({int productId, int actualQuantity, int difference})> adjustments,
    required int userId,
    String? reason,
  }) async {
    final db = await _db;

    await db.transaction((txn) async {
      for (final adj in adjustments) {
        await txn.update(
          'products',
          {'quantity': adj.actualQuantity},
          where: 'id = ?',
          whereArgs: [adj.productId],
        );
        await txn.insert('stock_movements', {
          'product_id': adj.productId,
          'user_id': userId,
          'type': AppConstants.movementAdjustment,
          'quantity_change': adj.difference,
          'reason': reason ?? 'Stock count adjustment',
        });
      }
    });
  }
}
