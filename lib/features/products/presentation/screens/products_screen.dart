import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/categories/data/categories_provider.dart';
import 'package:mobile_shop_management_system/features/products/data/products_filter.dart';
import 'package:mobile_shop_management_system/features/products/data/products_provider.dart';
import 'package:mobile_shop_management_system/features/products/models/product_model.dart';
import 'package:mobile_shop_management_system/features/products/presentation/widgets/product_form_dialog.dart';
import 'package:mobile_shop_management_system/features/products/presentation/widgets/view_imeis_dialog.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final filter = ref.watch(productsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () => _handleAdd(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by name or barcode',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) =>
                        ref.read(productsFilterProvider.notifier).setQuery(value),
                  ),
                ),
                const SizedBox(width: 12),
                categoriesAsync.when(
                  data: (categories) => DropdownButton<int?>(
                    value: filter.categoryId,
                    hint: const Text('All categories'),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                      ...categories.map(
                        (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                      ),
                    ],
                    onChanged: (value) =>
                        ref.read(productsFilterProvider.notifier).setCategory(value),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: productsAsync.when(
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('No products found.'));
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final lowStock = product.quantity <= 5;
                    return ListTile(
                      title: Row(
                        children: [
                          Flexible(child: Text(product.name)),
                          if (product.isImeiTracked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'IMEI',
                                style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        '${product.barcode ?? 'No barcode'} · \$${product.price.toStringAsFixed(2)} · Qty: ${product.quantity}',
                      ),
                      leading: lowStock
                          ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                          : const Icon(Icons.inventory_2_outlined),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (product.isImeiTracked)
                            IconButton(
                              icon: const Icon(Icons.qr_code_2_outlined),
                              tooltip: 'View IMEIs',
                              onPressed: () => showDialog(
                                context: context,
                                builder: (_) => ViewImeisDialog(product: product),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _handleEdit(context, ref, product),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _handleDelete(context, ref, product),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error loading products: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context, WidgetRef ref) async {
    final product = await showDialog<ProductModel>(
      context: context,
      builder: (_) => const ProductFormDialog(),
    );
    if (product == null) return;

    try {
      await ref.read(productsProvider.notifier).addProduct(product);
    } on ProductOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _handleEdit(BuildContext context, WidgetRef ref, ProductModel product) async {
    final updated = await showDialog<ProductModel>(
      context: context,
      builder: (_) => ProductFormDialog(existing: product),
    );
    if (updated == null) return;

    try {
      await ref.read(productsProvider.notifier).updateProduct(updated);
    } on ProductOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(productsProvider.notifier).deleteProduct(product.id!);
    } on ProductOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
