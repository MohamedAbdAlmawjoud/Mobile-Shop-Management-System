import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_shop_management_system/core/constants/app_constants.dart';
import 'package:mobile_shop_management_system/core/database/database_service.dart';
import 'package:mobile_shop_management_system/features/products/models/product_model.dart';
import 'report_models.dart';

class ReportsRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  /// Sales within [start, end] inclusive (dates only — time-of-day ignored),
  /// optionally restricted to one cashier via [userId].
  Future<SalesReportData> getSalesReport({
    required DateTime start,
    required DateTime end,
    int? userId,
  }) async {
    final db = await _db;
    final startStr = _dateOnly(start);
    // Add 1 day to end so the range is inclusive of the whole end date.
    final endStr = _dateOnly(end.add(const Duration(days: 1)));

    final where = StringBuffer('date(sales.created_at) >= ? AND date(sales.created_at) < ?');
    final args = <Object?>[startStr, endStr];
    if (userId != null) {
      where.write(' AND sales.user_id = ?');
      args.add(userId);
    }

    final rows = await db.rawQuery('''
      SELECT
        sales.id,
        sales.total,
        sales.payment_method,
        sales.created_at,
        users.username,
        (SELECT COALESCE(SUM(sale_items.quantity), 0) FROM sale_items WHERE sale_items.sale_id = sales.id) as item_count
      FROM sales
      JOIN users ON users.id = sales.user_id
      WHERE $where
      ORDER BY sales.created_at DESC
    ''', args);

    final salesRows = rows
        .map((r) => SalesReportRow(
              saleId: r['id'] as int,
              createdAt: DateTime.parse(r['created_at'] as String),
              cashierUsername: r['username'] as String,
              paymentMethod: r['payment_method'] as String,
              total: (r['total'] as num).toDouble(),
              itemCount: r['item_count'] as int,
            ))
        .toList();

    final totalRevenue = salesRows.fold(0.0, (sum, r) => sum + r.total);
    final totalItemsSold = salesRows.fold(0, (sum, r) => sum + r.itemCount);

    return SalesReportData(
      sales: salesRows,
      totalRevenue: totalRevenue,
      totalSalesCount: salesRows.length,
      totalItemsSold: totalItemsSold,
    );
  }

  Future<InventoryReportData> getInventoryReport() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT products.*, categories.name as category_name
      FROM products
      JOIN categories ON categories.id = products.category_id
      ORDER BY products.name ASC
    ''');

    final reportRows = rows
        .map((r) => InventoryReportRow(
              product: ProductModel.fromMap(r),
              categoryName: r['category_name'] as String,
            ))
        .toList();

    final totalStockValue = reportRows.fold(0.0, (sum, r) => sum + r.stockValue);
    final totalUnits = reportRows.fold(0, (sum, r) => sum + r.product.quantity);

    return InventoryReportData(
      rows: reportRows,
      totalStockValue: totalStockValue,
      totalUnits: totalUnits,
    );
  }

  Future<List<ProductModel>> getLowStockReport({int threshold = 5}) async {
    final db = await _db;
    final rows = await db.query(
      'products',
      where: 'quantity <= ?',
      whereArgs: [threshold],
      orderBy: 'quantity ASC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<List<AdjustmentReportRow>> getAdjustmentReport() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT
        stock_movements.quantity_change,
        stock_movements.reason,
        stock_movements.created_at,
        products.name as product_name,
        users.username
      FROM stock_movements
      JOIN products ON products.id = stock_movements.product_id
      JOIN users ON users.id = stock_movements.user_id
      WHERE stock_movements.type = ?
      ORDER BY stock_movements.created_at DESC
    ''', [AppConstants.movementAdjustment]);

    return rows
        .map((r) => AdjustmentReportRow(
              productName: r['product_name'] as String,
              quantityChange: r['quantity_change'] as int,
              reason: r['reason'] as String?,
              username: r['username'] as String,
              createdAt: DateTime.parse(r['created_at'] as String),
            ))
        .toList();
  }

  String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
