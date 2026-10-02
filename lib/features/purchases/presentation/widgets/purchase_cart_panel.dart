import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../suppliers/data/suppliers_provider.dart';
import '../../data/purchase_cart_provider.dart';
import '../../data/purchases_provider.dart';
import '../../data/purchases_repository.dart';

class PurchaseCartPanel extends ConsumerWidget {
  const PurchaseCartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(purchaseCartProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final selectedSupplierId = ref.watch(selectedSupplierIdProvider);
    final total = ref.read(purchaseCartProvider.notifier).total;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('Purchase', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (cart.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(purchaseCartProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: suppliersAsync.when(
            data: (suppliers) {
              if (suppliers.isEmpty) {
                return const Text(
                  'No suppliers yet — add one in Suppliers first.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                );
              }
              return DropdownButtonFormField<int>(
                initialValue: selectedSupplierId,
                decoration: const InputDecoration(labelText: 'Supplier'),
                items: suppliers
                    .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (value) => ref.read(selectedSupplierIdProvider.notifier).state = value,
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, st) => Text('Error: $e'),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? const Center(child: Text('No items yet. Tap a product to receive stock.'))
              : ListView.separated(
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.product.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${item.subtotal.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.isImeiLine
                                      ? '${item.quantity} unit(s) (IMEI) · \$${item.unitCost.toStringAsFixed(2)} each'
                                      : 'Qty ${item.quantity} · \$${item.unitCost.toStringAsFixed(2)} each',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () =>
                                    ref.read(purchaseCartProvider.notifier).removeLine(item),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cost', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: (cart.isEmpty || selectedSupplierId == null)
                    ? null
                    : () => _checkout(context, ref),
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('Complete Purchase'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(purchaseCheckoutControllerProvider);

    try {
      final purchaseId = await controller.checkout();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase #$purchaseId received.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PurchaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}
