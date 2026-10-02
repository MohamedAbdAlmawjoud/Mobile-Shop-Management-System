class ProductImei {
  final int id;
  final int productId;
  final String imei;
  final String status; // 'in_stock' or 'sold'
  final int? saleId;
  final DateTime createdAt;

  const ProductImei({
    required this.id,
    required this.productId,
    required this.imei,
    required this.status,
    this.saleId,
    required this.createdAt,
  });

  bool get isInStock => status == 'in_stock';

  factory ProductImei.fromMap(Map<String, Object?> map) {
    return ProductImei(
      id: map['id'] as int,
      productId: map['product_id'] as int,
      imei: map['imei'] as String,
      status: map['status'] as String,
      saleId: map['sale_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

/// Result of looking up a single IMEI — includes product/sale context,
/// used for the "look up this IMEI" warranty/support tool.
class ImeiLookupResult {
  final ProductImei imei;
  final String productName;
  final DateTime? soldAt;
  final String? soldByUsername;

  const ImeiLookupResult({
    required this.imei,
    required this.productName,
    this.soldAt,
    this.soldByUsername,
  });
}
