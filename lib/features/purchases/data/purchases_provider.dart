import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_provider.dart';
import '../../dashboard/data/dashboard_provider.dart';
import '../../inventory/data/inventory_provider.dart';
import '../../products/data/imei_provider.dart';
import '../../products/data/products_provider.dart';
import '../../sales/data/pos_products_provider.dart';
import 'purchase_cart_item.dart';
import 'purchase_cart_provider.dart';
import 'purchase_models.dart';
import 'purchases_repository.dart';

final purchasesRepositoryProvider = Provider((ref) => PurchasesRepository());

final purchaseHistoryProvider = FutureProvider<List<PurchaseHistoryRow>>((ref) async {
  final repo = ref.read(purchasesRepositoryProvider);
  return repo.getHistory();
});

class PurchaseCheckoutController {
  PurchaseCheckoutController(this.ref);
  final Ref ref;

  Future<int> checkout({String? notes}) async {
    final user = ref.read(authProvider);
    if (user == null) {
      throw const PurchaseException('You must be logged in.');
    }
    final supplierId = ref.read(selectedSupplierIdProvider);
    if (supplierId == null) {
      throw const PurchaseException('Select a supplier first.');
    }
    final items = ref.read(purchaseCartProvider);
    if (items.isEmpty) {
      throw const PurchaseException('Add at least one item.');
    }

    final repo = ref.read(purchasesRepositoryProvider);
    final purchaseId = await repo.completePurchase(
      supplierId: supplierId,
      items: items,
      userId: user.id!,
      notes: notes,
    );

    ref.read(purchaseCartProvider.notifier).clear();
    ref.invalidate(purchaseHistoryProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(posProductsProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(movementHistoryProvider);
    // Refresh IMEI lists for every product that had an IMEI line in this
    // purchase, so View IMEIs / the sales picker show the new units.
    for (final item in items) {
      if (item.isImeiLine) {
        ref.invalidate(productImeisProvider(item.product.id!));
      }
    }
    await ref.read(dashboardProvider.notifier).refresh();

    return purchaseId;
  }
}

final purchaseCheckoutControllerProvider = Provider((ref) => PurchaseCheckoutController(ref));
