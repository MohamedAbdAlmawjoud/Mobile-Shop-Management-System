import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../core/database/database_service.dart';
import '../../products/models/product_model.dart';
import 'dashboard_stats.dart';

/// Low-stock threshold: a product with quantity <= this is flagged.
/// Kept here for now; move to a configurable app setting later if needed.
const int lowStockThreshold = 5;

class DashboardRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  Future<DashboardStats> getStats() async {
    final db = await _db;

    // Today's sales total + count.
    final todayRow = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) as total, COUNT(*) as count
      FROM sales
      WHERE date(created_at) = date('now', 'localtime')
    ''');
    final todaySalesTotal = (todayRow.first['total'] as num).toDouble();
    final todaySalesCount = todayRow.first['count'] as int;

    // Total product count.
    final productCountRow = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    final totalProducts = productCountRow.first['count'] as int;

    // Low-stock products.
    final lowStockRows = await db.query(
      'products',
      where: 'quantity <= ?',
      whereArgs: [lowStockThreshold],
      orderBy: 'quantity ASC',
      limit: 20,
    );
    final lowStockProducts = lowStockRows.map(ProductModel.fromMap).toList();

    // Recent sales, joined with the cashier's username.
    final recentRows = await db.rawQuery('''
      SELECT sales.id, sales.total, sales.payment_method, sales.created_at, users.username
      FROM sales
      JOIN users ON users.id = sales.user_id
      ORDER BY sales.created_at DESC
      LIMIT 10
    ''');
    final recentSales = recentRows
        .map((row) => RecentSale(
              id: row['id'] as int,
              total: (row['total'] as num).toDouble(),
              paymentMethod: row['payment_method'] as String,
              cashierUsername: row['username'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
            ))
        .toList();

    return DashboardStats(
      todaySalesTotal: todaySalesTotal,
      todaySalesCount: todaySalesCount,
      totalProducts: totalProducts,
      lowStockProducts: lowStockProducts,
      recentSales: recentSales,
    );
  }
}
