import 'package:mobile_shop_management_system/features/products/models/product_model.dart';

/// Purchase line. IMEI-tracked quantities match the number of serials entered.
class PurchaseCartItem {
  final ProductModel product;
  final int quantity;
  final double unitCost;
  final List<String>? imeis;

  const PurchaseCartItem({
    required this.product,
    required this.quantity,
    required this.unitCost,
    this.imeis,
  });

  bool get isImeiLine => imeis != null;

  double get subtotal => unitCost * quantity;
}
