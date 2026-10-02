import '../../products/models/product_model.dart';

/// One row in the Sales Report — a single sale with its line items,
/// enough to show a breakdown without re-querying per row in the UI.
class SalesReportRow {
  final int saleId;
  final DateTime createdAt;
  final String cashierUsername;
  final String paymentMethod;
  final double total;
  final int itemCount;

  const SalesReportRow({
    required this.saleId,
    required this.createdAt,
    required this.cashierUsername,
    required this.paymentMethod,
    required this.total,
    required this.itemCount,
  });
}

class SalesReportData {
  final List<SalesReportRow> sales;
  final double totalRevenue;
  final int totalSalesCount;
  final int totalItemsSold;

  const SalesReportData({
    required this.sales,
    required this.totalRevenue,
    required this.totalSalesCount,
    required this.totalItemsSold,
  });
}

/// Inventory Report — every product with its current value (price * qty).
class InventoryReportRow {
  final ProductModel product;
  final String categoryName;

  const InventoryReportRow({required this.product, required this.categoryName});

  double get stockValue => product.price * product.quantity;
}

class InventoryReportData {
  final List<InventoryReportRow> rows;
  final double totalStockValue;
  final int totalUnits;

  const InventoryReportData({
    required this.rows,
    required this.totalStockValue,
    required this.totalUnits,
  });
}

/// Adjustment Report — every ADJUSTMENT stock movement (from stock counts).
class AdjustmentReportRow {
  final String productName;
  final int quantityChange;
  final String? reason;
  final String username;
  final DateTime createdAt;

  const AdjustmentReportRow({
    required this.productName,
    required this.quantityChange,
    this.reason,
    required this.username,
    required this.createdAt,
  });
}
