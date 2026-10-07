import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/auth/data/auth_provider.dart';
import 'package:mobile_shop_management_system/features/dashboard/data/dashboard_provider.dart';
import 'package:mobile_shop_management_system/features/inventory/data/inventory_provider.dart';
import 'package:mobile_shop_management_system/features/products/data/products_provider.dart';
import 'package:mobile_shop_management_system/features/sales/data/pos_products_provider.dart';
import 'stock_count_entry.dart';
import 'stock_count_repository.dart';

final stockCountRepositoryProvider = Provider((ref) => StockCountRepository());

class StockCountException implements Exception {
  final String message;
  const StockCountException(this.message);
}

/// A stock count "session": one entry per product, loaded fresh each time
/// the Stock Count screen is opened. Entries are UI-only until approved.
class StockCountNotifier extends AsyncNotifier<List<StockCountEntry>> {
  @override
  Future<List<StockCountEntry>> build() async {
    final repo = ref.read(productsRepositoryProvider);
    final products = await repo.search();
    // IMEI-tracked products aren't included: their quantity is derived from
    // individual in-stock IMEI records, not a plain number, so a blind
    // "set quantity to X" here would desync them from product_imeis.
    // Reconciling those needs a per-unit workflow, not this screen.
    return products
        .where((p) => !p.isImeiTracked)
        .map((p) => StockCountEntry(product: p))
        .toList();
  }

  void setActualQuantity(int productId, int actualQuantity) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([
      for (final entry in current)
        if (entry.product.id == productId)
          entry.copyWith(actualQuantity: actualQuantity)
        else
          entry,
    ]);
  }

  /// Applies every counted entry whose actual quantity differs from the
  /// system quantity. Entries left uncounted, or counted with no
  /// difference, are skipped — nothing is written for them.
  Future<int> approve({String? reason}) async {
    final user = ref.read(authProvider);
    if (user == null) {
      throw const StockCountException('You must be logged in.');
    }

    final entries = state.value ?? [];
    final toApply = entries.where((e) => e.isCounted && e.difference != 0).toList();

    if (toApply.isEmpty) {
      throw const StockCountException('No quantity differences to apply.');
    }

    final repo = ref.read(stockCountRepositoryProvider);
    await repo.applyBatch(
      adjustments: [
        for (final e in toApply)
          (productId: e.product.id!, actualQuantity: e.actualQuantity!, difference: e.difference!),
      ],
      userId: user.id!,
      reason: reason,
    );

    ref.invalidateSelf();
    await future;
    ref.invalidate(productsProvider);
    ref.invalidate(posProductsProvider);
    ref.invalidate(inventoryProvider);
    ref.invalidate(movementHistoryProvider);
    await ref.read(dashboardProvider.notifier).refresh();

    return toApply.length;
  }
}

final stockCountProvider = AsyncNotifierProvider<StockCountNotifier, List<StockCountEntry>>(
  StockCountNotifier.new,
);
