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

  /// Adds a product, or increments quantity if it's already in the cart.
  /// Refuses to exceed the product's current known stock — this is a
  /// friendly UI-level check; the transaction in SalesRepository is the
  /// real source of truth and re-checks stock at checkout time.
  void addProduct(ProductModel product) {
    final index = state.indexWhere((item) => item.product.id == product.id);

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
        if (item.product.id == product.id) item.copyWith(quantity: item.quantity + 1) else item,
    ];
  }

  void setQuantity(int productId, int quantity) {
    final index = state.indexWhere((item) => item.product.id == productId);
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
        if (item.product.id == productId) item.copyWith(quantity: quantity) else item,
    ];
  }

  void removeProduct(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = [];
  }

  double get total => state.fold(0.0, (sum, item) => sum + item.subtotal);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
