import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_model.dart';
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
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _repo.delete(id);
      ref.invalidateSelf();
      await future;
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
}

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<ProductModel>>(
  ProductsNotifier.new,
);
