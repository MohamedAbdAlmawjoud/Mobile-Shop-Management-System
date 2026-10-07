import 'package:mobile_shop_management_system/features/products/models/product_model.dart';

/// One line in an in-progress stock count session — UI-only until approved.
class StockCountEntry {
  final ProductModel product;
  final int? actualQuantity; // null = not yet counted

  const StockCountEntry({required this.product, this.actualQuantity});

  int get systemQuantity => product.quantity;

  /// actual - system. Null if not yet counted.
  int? get difference => actualQuantity == null ? null : actualQuantity! - systemQuantity;

  bool get isShortage => (difference ?? 0) < 0;
  bool get isExcess => (difference ?? 0) > 0;
  bool get isCounted => actualQuantity != null;

  StockCountEntry copyWith({int? actualQuantity}) {
    return StockCountEntry(product: product, actualQuantity: actualQuantity);
  }
}
