import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'purchase_cart_item.dart';

class PurchaseCartException implements Exception {
  final String message;
  const PurchaseCartException(this.message);
}

/// Selected supplier for the purchase currently being built. Null until
/// the user picks one — required before checkout.
final selectedSupplierIdProvider = StateProvider<int?>((ref) => null);

class PurchaseCartNotifier extends Notifier<List<PurchaseCartItem>> {
  @override
  List<PurchaseCartItem> build() => [];

  void addLine(PurchaseCartItem item) {
    if (!item.isImeiLine) {
      // Merge with an existing regular (non-IMEI) line for the same
      // product, same as the sales cart does — but only if the unit cost
      // matches, since a different cost this time is a distinct batch.
      final index = state.indexWhere(
        (i) => i.product.id == item.product.id && !i.isImeiLine && i.unitCost == item.unitCost,
      );
      if (index != -1) {
        final existing = state[index];
        state = [
          for (final line in state)
            if (line == existing)
              PurchaseCartItem(
                product: line.product,
                quantity: line.quantity + item.quantity,
                unitCost: line.unitCost,
              )
            else
              line,
        ];
        return;
      }
    }
    state = [...state, item];
  }

  void removeLine(PurchaseCartItem item) {
    state = state.where((line) => line != item).toList();
  }

  void clear() {
    state = [];
  }

  double get total => state.fold(0.0, (sum, item) => sum + item.subtotal);
}

final purchaseCartProvider =
    NotifierProvider<PurchaseCartNotifier, List<PurchaseCartItem>>(PurchaseCartNotifier.new);
