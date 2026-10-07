import 'package:mobile_shop_management_system/features/products/models/product_model.dart';

/// Cart line. IMEI-tracked units have one serial number and quantity 1.
class CartItem {
  final ProductModel product;
  final int quantity;
  final String? imei;

  const CartItem({required this.product, required this.quantity, this.imei});

  bool get isImeiUnit => imei != null;

  double get subtotal => product.price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity, imei: imei);
  }
}
