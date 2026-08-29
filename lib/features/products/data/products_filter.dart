import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current search text + category filter for the Products screen.
/// Kept separate from ProductsNotifier so the search bar and category
/// dropdown can update it independently without knowing about the
/// data-loading logic.
class ProductsFilter {
  final String query;
  final int? categoryId; // null = all categories

  const ProductsFilter({this.query = '', this.categoryId});

  ProductsFilter copyWith({String? query, int? categoryId, bool clearCategory = false}) {
    return ProductsFilter(
      query: query ?? this.query,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
    );
  }
}

class ProductsFilterNotifier extends Notifier<ProductsFilter> {
  @override
  ProductsFilter build() => const ProductsFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void setCategory(int? categoryId) {
    state = categoryId == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(categoryId: categoryId);
  }
}

final productsFilterProvider =
    NotifierProvider<ProductsFilterNotifier, ProductsFilter>(ProductsFilterNotifier.new);
