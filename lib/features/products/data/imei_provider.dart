import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/auth/data/auth_provider.dart';
import 'package:mobile_shop_management_system/features/dashboard/data/dashboard_provider.dart';
import 'package:mobile_shop_management_system/features/inventory/data/inventory_provider.dart';
import 'package:mobile_shop_management_system/features/sales/data/pos_products_provider.dart';
import 'imei_repository.dart';
import 'product_imei.dart';
import 'products_provider.dart';

final imeiRepositoryProvider = Provider((ref) => ImeiRepository());

/// In-stock IMEIs for one product — used by both the Sales picker and the
/// admin "View IMEIs" screen. Family-keyed by product id.
final productImeisProvider =
    FutureProvider.family<List<ProductImei>, int>((ref, productId) async {
  final repo = ref.read(imeiRepositoryProvider);
  return repo.getAllForProduct(productId);
});

class ImeiActions {
  ImeiActions(this.ref);
  final Ref ref;

  Future<void> stockIn({
    required int productId,
    required List<String> imeis,
    String? reason,
  }) async {
    final user = ref.read(authProvider);
    if (user == null) {
      throw const ImeiOperationException('You must be logged in.');
    }
    final repo = ref.read(imeiRepositoryProvider);
    await repo.stockInImeis(
      productId: productId,
      imeis: imeis,
      userId: user.id!,
      reason: reason,
    );
    _refreshEverything(productId);
  }

  Future<void> removeUnsold(int imeiRowId, int productId) async {
    final user = ref.read(authProvider);
    if (user == null) {
      throw const ImeiOperationException('You must be logged in.');
    }
    final repo = ref.read(imeiRepositoryProvider);
    await repo.removeUnsold(imeiRowId, userId: user.id!);
    _refreshEverything(productId);
  }

  void _refreshEverything(int productId) {
    ref.invalidate(productImeisProvider(productId));
    ref.invalidate(productsProvider);
    ref.invalidate(posProductsProvider);
    ref.invalidate(inventoryProvider);
    ref.read(dashboardProvider.notifier).refresh();
  }
}

final imeiActionsProvider = Provider((ref) => ImeiActions(ref));
