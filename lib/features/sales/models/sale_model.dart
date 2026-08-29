class SaleModel {
  final int? id;
  final int userId;
  final double total;
  final String paymentMethod;
  final DateTime? createdAt;

  const SaleModel({
    this.id,
    required this.userId,
    required this.total,
    required this.paymentMethod,
    this.createdAt,
  });

  factory SaleModel.fromMap(Map<String, Object?> map) {
    return SaleModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'total': total,
      'payment_method': paymentMethod,
    };
  }
}
