/// Read-only joined view of a stock_movements row for display purposes
/// (includes product name and username instead of just their ids).
class StockMovementView {
  final int id;
  final String type; // STOCK_IN, SALE, ADJUSTMENT
  final int quantityChange;
  final String? reason;
  final DateTime createdAt;
  final String productName;
  final String username;

  const StockMovementView({
    required this.id,
    required this.type,
    required this.quantityChange,
    this.reason,
    required this.createdAt,
    required this.productName,
    required this.username,
  });

  factory StockMovementView.fromMap(Map<String, Object?> map) {
    return StockMovementView(
      id: map['id'] as int,
      type: map['type'] as String,
      quantityChange: map['quantity_change'] as int,
      reason: map['reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      productName: map['product_name'] as String,
      username: map['username'] as String,
    );
  }
}
