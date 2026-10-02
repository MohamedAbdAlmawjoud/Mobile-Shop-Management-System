import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../products/models/product_model.dart';
import 'cart_item.dart';

class CartException implements Exception {
  final String message;
  const CartException(this.message);
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  /// Adds a regular (non-IMEI) product, or increments quantity if it's
  /// already in the cart. Refuses to exceed the product's current known
  /// stock — this is a friendly UI-level check; the transaction in
  /// SalesRepository is the real source of truth and re-checks at checkout.
  void addProduct(ProductModel product) {
    if (product.isImeiTracked) {
      throw CartException('${product.name} requires selecting a specific unit (IMEI).');
    }

    final index = state.indexWhere((item) => item.product.id == product.id && !item.isImeiUnit);

    if (index == -1) {
      if (product.quantity < 1) {
        throw CartException('${product.name} is out of stock.');
      }
      state = [...state, CartItem(product: product, quantity: 1)];
      return;
    }

    final existing = state[index];
    if (existing.quantity + 1 > product.quantity) {
      throw CartException('Only ${product.quantity} of ${product.name} in stock.');
    }
    state = [
      for (final item in state)
        if (item == existing) item.copyWith(quantity: item.quantity + 1) else item,
    ];
  }

  /// Adds one specific IMEI unit as its own cart line (quantity always 1,
  /// since each serialized unit is distinct — not interchangeable stock).
  void addImeiUnit(ProductModel product, String imei) {
    final alreadyInCart = state.any((item) => item.imei == imei);
    if (alreadyInCart) {
      throw CartException('That unit is already in the cart.');
    }
    state = [...state, CartItem(product: product, quantity: 1, imei: imei)];
  }

  /// Quantity changes only apply to regular (non-IMEI) lines — an IMEI
  /// line is always exactly 1 unit; use removeImeiUnit to remove one.
  void setQuantity(int productId, int quantity) {
    final index = state.indexWhere((item) => item.product.id == productId && !item.isImeiUnit);
    if (index == -1) return;

    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final product = state[index].product;
    if (quantity > product.quantity) {
      throw CartException('Only ${product.quantity} of ${product.name} in stock.');
    }
    state = [
      for (final item in state)
        if (item.product.id == productId && !item.isImeiUnit)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
  }

  /// Removes the regular (non-IMEI) line for this product, if any.
  void removeProduct(int productId) {
    state = state
        .where((item) => !(item.product.id == productId && !item.isImeiUnit))
        .toList();
  }

  /// Removes one specific IMEI cart line.
  void removeImeiUnit(String imei) {
    state = state.where((item) => item.imei != imei).toList();
  }

  void clear() {
    state = [];
  }

  double get total => state.fold(0.0, (sum, item) => sum + item.subtotal);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
