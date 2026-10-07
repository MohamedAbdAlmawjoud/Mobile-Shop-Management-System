import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/dashboard/data/dashboard_provider.dart';
import 'package:mobile_shop_management_system/features/inventory/data/inventory_provider.dart';
import 'package:mobile_shop_management_system/features/sales/data/pos_products_provider.dart';
import 'package:mobile_shop_management_system/features/products/models/product_model.dart';
import 'products_filter.dart';
import 'products_repository.dart';

final productsRepositoryProvider = Provider((ref) => ProductsRepository());

class ProductOperationException implements Exception {
  final String message;
  const ProductOperationException(this.message);
}

/// Watches productsFilterProvider, so any change to search text or category
/// filter automatically re-runs build() and refetches with the new filter.
class ProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  ProductsRepository get _repo => ref.read(productsRepositoryProvider);

  @override
  Future<List<ProductModel>> build() async {
    final filter = ref.watch(productsFilterProvider);
    return _repo.search(query: filter.query, categoryId: filter.categoryId);
  }

  Future<void> addProduct(ProductModel product) async {
    _validate(product);
    if (product.barcode != null &&
        product.barcode!.isNotEmpty &&
        await _repo.barcodeExists(product.barcode!)) {
      throw const ProductOperationException('A product with this barcode already exists.');
    }
    await _repo.insert(product);
    ref.invalidateSelf();
    await future;
    _refreshElsewhere();
  }

  Future<void> updateProduct(ProductModel product) async {
    _validate(product);
    if (product.barcode != null &&
        product.barcode!.isNotEmpty &&
        await _repo.barcodeExists(product.barcode!, excludingId: product.id)) {
      throw const ProductOperationException('A product with this barcode already exists.');
    }
    await _repo.update(product);
    ref.invalidateSelf();
    await future;
    _refreshElsewhere();
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repo.delete(id);
      ref.invalidateSelf();
      await future;
      _refreshElsewhere();
    } on Exception catch (e) {
      if (e.toString().toLowerCase().contains('foreign key')) {
        throw const ProductOperationException(
          'Cannot delete this product — it has sales or stock history.',
        );
      }
      rethrow;
    }
  }

  void _validate(ProductModel product) {
    if (product.name.trim().isEmpty) {
      throw const ProductOperationException('Product name cannot be empty.');
    }
    if (product.price < 0) {
      throw const ProductOperationException('Price cannot be negative.');
    }
    if (product.quantity < 0) {
      throw const ProductOperationException('Quantity cannot be negative.');
    }
  }

  // Anything created/edited/deleted here also needs to be reflected in the
  // Inventory tab, the POS product grid, and the Dashboard's product count.
  void _refreshElsewhere() {
    ref.invalidate(inventoryProvider);
    ref.invalidate(posProductsProvider);
    ref.read(dashboardProvider.notifier).refresh();
  }
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<ProductModel>>(
  ProductsNotifier.new,
);
