import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../products/data/products_provider.dart';
import '../../products/models/product_model.dart';

/// POS has its own search box, deliberately separate from the Products
/// screen's search/filter state — searching for a product to sell shouldn't
/// change what the Products management screen is filtered to, and vice versa.
final posSearchQueryProvider = StateProvider<String>((ref) => '');

class PosProductsNotifier extends AsyncNotifier<List<ProductModel>> {
  @override
  Future<List<ProductModel>> build() async {
    final query = ref.watch(posSearchQueryProvider);
    final repo = ref.read(productsRepositoryProvider);
    return repo.search(query: query);
  }
}

final posProductsProvider = AsyncNotifierProvider<PosProductsNotifier, List<ProductModel>>(
  PosProductsNotifier.new,
);
