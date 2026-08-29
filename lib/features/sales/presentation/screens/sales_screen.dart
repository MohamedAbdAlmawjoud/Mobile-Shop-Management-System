import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/models/product_model.dart';
import '../../data/cart_provider.dart';
import '../../data/pos_products_provider.dart';
import '../../data/sales_provider.dart';
import '../widgets/cart_panel.dart';

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or scan barcode',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        ref.read(posSearchQueryProvider.notifier).state = value,
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
                                      : () => _addToCart(context, ref, product),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          product.name,
                                          style: Theme.of(context).textTheme.titleSmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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

  void _addToCart(BuildContext context, WidgetRef ref, ProductModel product) {
    try {
      ref.read(cartProvider.notifier).addProduct(product);
    } on CartException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }
}
