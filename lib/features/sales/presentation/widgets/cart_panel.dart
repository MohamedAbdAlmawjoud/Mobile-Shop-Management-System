import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cart_provider.dart';
import '../../data/sales_provider.dart';

const List<String> paymentMethods = ['Cash', 'Card', 'Mobile Payment'];

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final selectedPayment = ref.watch(selectedPaymentMethodProvider);
    final total = ref.read(cartProvider.notifier).total;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Text('Cart', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              if (cart.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(cartProvider.notifier).clear(),
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? const Center(child: Text('Cart is empty. Tap a product to add it.'))
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
                          // Line 1: name + subtotal
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
                          // Line 2: unit price + quantity controls + delete
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '\$${item.product.price.toStringAsFixed(2)} each',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.remove_circle_outline, size: 20),
                                onPressed: () => _changeQty(
                                  context,
                                  ref,
                                  item.product.id!,
                                  item.quantity - 1,
                                ),
                              ),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${item.quantity}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                onPressed: () => _changeQty(
                                  context,
                                  ref,
                                  item.product.id!,
                                  item.quantity + 1,
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => ref
                                    .read(cartProvider.notifier)
                                    .removeProduct(item.product.id!),
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
                  Text('Total', style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedPayment,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(selectedPaymentMethodProvider.notifier).state = value;
                  }
                },
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: cart.isEmpty ? null : () => _checkout(context, ref),
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('Confirm Checkout'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _changeQty(BuildContext context, WidgetRef ref, int productId, int newQty) {
    try {
      ref.read(cartProvider.notifier).setQuantity(productId, newQty);
    } on CartException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _checkout(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    final controller = ref.read(checkoutControllerProvider);

    try {
      final saleId = await controller.checkout(cart);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sale #$saleId completed.'), backgroundColor: Colors.green),
        );
      }
    } on CheckoutException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}