import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/auth/data/auth_provider.dart';
import 'package:mobile_shop_management_system/features/dashboard/data/dashboard_provider.dart';
import 'package:mobile_shop_management_system/features/products/data/products_provider.dart';
import 'package:mobile_shop_management_system/features/products/models/product_model.dart';
import 'package:mobile_shop_management_system/features/sales/data/pos_products_provider.dart';
import 'inventory_repository.dart';
import 'stock_movement_view.dart';

final inventoryRepositoryProvider = Provider((ref) => InventoryRepository());

class InventoryOperationException implements Exception {
  final String message;
  const InventoryOperationException(this.message);
}

class InventoryNotifier extends AsyncNotifier<List<ProductModel>> {
  InventoryRepository get _repo => ref.read(inventoryRepositoryProvider);

  @override
  Future<List<ProductModel>> build() async {
    return _repo.getAllProducts();
  }

  Future<void> stockIn({
    required int productId,
    required int quantity,
    String? reason,
  }) async {
    final user = ref.read(authProvider);
    if (user == null) {
      throw const InventoryOperationException('You must be logged in.');
    }
    if (quantity <= 0) {
      throw const InventoryOperationException('Quantity must be greater than zero.');
    }

    await _repo.stockIn(
      productId: productId,
      quantity: quantity,
      userId: user.id!,
      reason: reason,
    );

    ref.invalidateSelf();
    await future;
    // Stock changed — keep Products, POS, movement history, and Dashboard in sync.
    ref.invalidate(productsProvider);
    ref.invalidate(posProductsProvider);
    ref.invalidate(movementHistoryProvider);
    await ref.read(dashboardProvider.notifier).refresh();
  }
}

final inventoryProvider = AsyncNotifierProvider<InventoryNotifier, List<ProductModel>>(
  InventoryNotifier.new,
);

/// Movement history for the whole inventory (or a single product if
/// productIdFilter is set).
final movementHistoryProvider =
    FutureProvider.family<List<StockMovementView>, int?>((ref, productId) async {
  final repo = ref.read(inventoryRepositoryProvider);
  return repo.getMovementHistory(productId: productId);
});
