import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/data/products_provider.dart';
import '../../../products/models/product_model.dart';
import '../../data/cart_provider.dart';
import '../../data/pos_products_provider.dart';
import '../../data/sales_provider.dart';
import '../widgets/cart_panel.dart';
import '../widgets/select_imei_dialog.dart';

class SalesScreen extends ConsumerStatefulWidget {
  const SalesScreen({super.key});

  @override
  ConsumerState<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends ConsumerState<SalesScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(posProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales / POS')),
      body: Row(
        children: [
          // Left: product search + tap-to-add list
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or scan barcode',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        ref.read(posSearchQueryProvider.notifier).state = value,
                    // USB barcode scanners act as keyboards: they type the
                    // barcode digits rapidly, then send Enter. If what's
                    // typed exactly matches a product's barcode, treat it
                    // as a scan and add straight to cart instead of just
                    // filtering the list.
                    onSubmitted: (value) => _handleSubmit(context, value),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: productsAsync.when(
                    data: (products) {
                      if (products.isEmpty) {
                        return const Center(child: Text('No products found.'));
                      }
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: products.map((product) {
                            final outOfStock = product.quantity < 1;
                            return SizedBox(
                              width: 200,
                              height: 140,
                              child: Card(
                                child: InkWell(
                                  onTap: outOfStock
                                      ? null
                                      : () => product.isImeiTracked
                                          ? _pickImeiAndAdd(context, product)
                                          : _addToCart(context, product),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                product.name,
                                                style: Theme.of(context).textTheme.titleSmall,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (product.isImeiTracked)
                                              const Padding(
                                                padding: EdgeInsets.only(left: 4),
                                                child: Icon(Icons.qr_code_2, size: 14, color: Colors.blue),
                                              ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('\$${product.price.toStringAsFixed(2)}'),
                                            Text(
                                              outOfStock
                                                  ? 'Out of stock'
                                                  : 'Qty: ${product.quantity}',
                                              style: TextStyle(
                                                color: outOfStock ? Colors.red : Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text('Error loading products: $e')),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right: cart panel
          const Expanded(
            flex: 2,
            child: CartPanel(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final repo = ref.read(productsRepositoryProvider);
    final product = await repo.getByBarcode(trimmed);

    if (product == null) {
      // No exact barcode match — leave it as a plain text search
      // (posSearchQueryProvider already filters the grid via onChanged).
      return;
    }

    if (!context.mounted) return;

    if (product.isImeiTracked) {
      // This scanned the product's own barcode, not a specific unit's IMEI.
      // Still need to know which unit — open the picker (which also
      // accepts a direct IMEI scan itself).
      await _pickImeiAndAdd(context, product);
    } else {
      _addToCart(context, product);
    }

    // Clear the field and keep focus so the next scan can go straight in
    // without the cashier needing to click back into the search box.
    _searchController.clear();
    ref.read(posSearchQueryProvider.notifier).state = '';
    _searchFocusNode.requestFocus();
  }

  void _addToCart(BuildContext context, ProductModel product) {
    try {
      ref.read(cartProvider.notifier).addProduct(product);
    } on CartException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickImeiAndAdd(BuildContext context, ProductModel product) async {
    final imei = await showDialog<String>(
      context: context,
      builder: (_) => SelectImeiDialog(product: product),
    );
    if (imei == null || imei.isEmpty) return;
    if (!context.mounted) return;

    try {
      ref.read(cartProvider.notifier).addImeiUnit(product, imei);
    } on CartException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }
}
