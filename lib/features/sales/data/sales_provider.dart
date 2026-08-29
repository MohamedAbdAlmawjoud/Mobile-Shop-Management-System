import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../auth/data/auth_provider.dart';
import '../../dashboard/data/dashboard_provider.dart';
import '../../products/data/products_provider.dart';
import 'cart_item.dart';
import 'cart_provider.dart';
import 'pos_products_provider.dart';
import 'sales_repository.dart';

final salesRepositoryProvider = Provider((ref) => SalesRepository());

/// Selected payment method for the current sale in progress.
final selectedPaymentMethodProvider = StateProvider<String>((ref) => 'Cash');

class CheckoutException implements Exception {
  final String message;
  const CheckoutException(this.message);
}

/// Orchestrates checkout: calls the repository's transactional completeSale,
/// then clears the cart and refreshes Products + Dashboard so stock and
/// dashboard numbers reflect the sale immediately across the app.
class CheckoutController {
  CheckoutController(this.ref);
  final Ref ref;

  Future<int> checkout(List<CartItem> items) async {
    final user = ref.read(authProvider);
    if (user == null) {
      throw const CheckoutException('You must be logged in to complete a sale.');
    }
    if (items.isEmpty) {
      throw const CheckoutException('Cart is empty.');
    }

    final paymentMethod = ref.read(selectedPaymentMethodProvider);
    final repo = ref.read(salesRepositoryProvider);

    try {
      final saleId = await repo.completeSale(
        items: items,
        paymentMethod: paymentMethod,
        userId: user.id!,
      );

      ref.read(cartProvider.notifier).clear();
      // Refresh anything that depends on product quantities or sales totals.
      ref.invalidate(productsProvider);
      ref.invalidate(posProductsProvider);
      await ref.read(dashboardProvider.notifier).refresh();

      return saleId;
    } on InsufficientStockException catch (e) {
      throw CheckoutException(e.message);
    }
  }
}

final checkoutControllerProvider = Provider((ref) => CheckoutController(ref));
