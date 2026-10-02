import '../../products/models/product_model.dart';

/// UI-only purchase line — not persisted until the purchase is completed.
///
/// For a regular product, [imeis] is null and [quantity] is entered
/// directly. For an IMEI-tracked product, [imeis] holds the specific units
/// being received and [quantity] is always imeis.length — each unit needs
/// its own serial recorded, same rule as Inventory's IMEI stock-in.
class PurchaseCartItem {
  final ProductModel product;
  final int quantity;
  final double unitCost;
  final List<String>? imeis;

  const PurchaseCartItem({
    required this.product,
    required this.quantity,
    required this.unitCost,
    this.imeis,
  });

  bool get isImeiLine => imeis != null;

  double get subtotal => unitCost * quantity;
}
