/// Full detail for one sale, including line items — used to render an
/// invoice. Distinct from the lighter SalesReportRow/RecentSale, which
/// don't include items.
class SaleDetailItem {
  final String productName;
  final int quantity;
  final double unitPrice;

  const SaleDetailItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get subtotal => quantity * unitPrice;
}

class SaleDetail {
  final int saleId;
  final DateTime createdAt;
  final String cashierUsername;
  final String paymentMethod;
  final double total;
  final List<SaleDetailItem> items;

  const SaleDetail({
    required this.saleId,
    required this.createdAt,
    required this.cashierUsername,
    required this.paymentMethod,
    required this.total,
    required this.items,
  });
}
