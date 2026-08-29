import '../../products/models/product_model.dart';

/// A single recent sale, with just enough info for the dashboard list
/// (avoids pulling in full SaleModel + a separate user lookup per row).
class RecentSale {
  final int id;
  final double total;
  final String paymentMethod;
  final String cashierUsername;
  final DateTime createdAt;

  const RecentSale({
    required this.id,
    required this.total,
    required this.paymentMethod,
    required this.cashierUsername,
    required this.createdAt,
  });
}

class DashboardStats {
  final double todaySalesTotal;
  final int todaySalesCount;
  final int totalProducts;
  final List<ProductModel> lowStockProducts;
  final List<RecentSale> recentSales;

  const DashboardStats({
    required this.todaySalesTotal,
    required this.todaySalesCount,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.recentSales,
  });
}
