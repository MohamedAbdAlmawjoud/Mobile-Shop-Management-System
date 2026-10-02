class ProductModel {
  final int? id;
  final int categoryId;
  final String name;
  final String? barcode;
  final double price;
  final int quantity;
  final bool isImeiTracked;
  final DateTime? createdAt;

  const ProductModel({
    this.id,
    required this.categoryId,
    required this.name,
    this.barcode,
    required this.price,
    required this.quantity,
    this.isImeiTracked = false,
    this.createdAt,
  });

  factory ProductModel.fromMap(Map<String, Object?> map) {
    return ProductModel(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      name: map['name'] as String,
      barcode: map['barcode'] as String?,
      price: (map['price'] as num).toDouble(),
      quantity: map['quantity'] as int,
      isImeiTracked: (map['is_imei_tracked'] as int? ?? 0) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'name': name,
      'barcode': barcode,
      'price': price,
      'quantity': quantity,
      'is_imei_tracked': isImeiTracked ? 1 : 0,
    };
  }

  ProductModel copyWith({
    int? id,
    int? categoryId,
    String? name,
    String? barcode,
    double? price,
    int? quantity,
    bool? isImeiTracked,
  }) {
    return ProductModel(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isImeiTracked: isImeiTracked ?? this.isImeiTracked,
      createdAt: createdAt,
    );
  }
}
