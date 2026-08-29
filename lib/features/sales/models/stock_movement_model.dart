class StockMovementModel {
  final int? id;
  final int productId;
  final int userId;
  final String type; // 'STOCK_IN', 'SALE', 'ADJUSTMENT'
  final int quantityChange; // positive or negative
  final String? reason;
  final DateTime? createdAt;

  const StockMovementModel({
    this.id,
    required this.productId,
    required this.userId,
    required this.type,
    required this.quantityChange,
    this.reason,
    this.createdAt,
  });

  factory StockMovementModel.fromMap(Map<String, Object?> map) {
    return StockMovementModel(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      quantityChange: map['quantity_change'] as int,
      reason: map['reason'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'product_id': productId,
      'user_id': userId,
      'type': type,
      'quantity_change': quantityChange,
      'reason': reason,
    };
  }
}
