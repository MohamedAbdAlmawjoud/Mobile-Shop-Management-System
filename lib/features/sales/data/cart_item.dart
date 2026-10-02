import '../../products/models/product_model.dart';

/// UI-only cart line item — not persisted until checkout.
///
/// For a regular product, [imei] is null and [quantity] can be any amount.
/// For an IMEI-tracked product, [imei] identifies the specific unit being
/// sold and [quantity] is always 1 — each IMEI is its own cart line, since
/// they're distinct serialized units, not interchangeable stock.
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
