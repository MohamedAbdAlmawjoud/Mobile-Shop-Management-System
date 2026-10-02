/// Summary row for the Purchase History list.
class PurchaseHistoryRow {
  final int purchaseId;
  final DateTime createdAt;
  final String supplierName;
  final String username;
  final double total;
  final int itemCount;

  const PurchaseHistoryRow({
    required this.purchaseId,
    required this.createdAt,
    required this.supplierName,
    required this.username,
    required this.total,
    required this.itemCount,
  });
}

class PurchaseDetailItem {
  final String productName;
  final int quantity;
  final double unitCost;

  const PurchaseDetailItem({
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  double get subtotal => quantity * unitCost;
}

class PurchaseDetail {
  final int purchaseId;
  final DateTime createdAt;
  final String supplierName;
  final String username;
  final double total;
  final String? notes;
  final List<PurchaseDetailItem> items;

  const PurchaseDetail({
    required this.purchaseId,
    required this.createdAt,
    required this.supplierName,
    required this.username,
    required this.total,
    this.notes,
    required this.items,
  });
}
