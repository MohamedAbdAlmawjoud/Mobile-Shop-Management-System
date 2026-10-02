import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../products/data/products_provider.dart';
import '../../../products/models/product_model.dart';
import '../../data/purchase_cart_item.dart';
import '../../data/purchase_cart_provider.dart';
import '../widgets/add_imei_purchase_line_dialog.dart';
import '../widgets/add_purchase_line_dialog.dart';
import '../widgets/purchase_cart_panel.dart';

class NewPurchaseScreen extends ConsumerWidget {
  const NewPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('No products yet.'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: products.map((product) {
                    return SizedBox(
                      width: 200,
                      height: 100,
                      child: Card(
                        child: InkWell(
                          onTap: () => _handleTap(context, ref, product),
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
                                Text(
                                  'Current qty: ${product.quantity}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        const VerticalDivider(width: 1),
        const Expanded(
          flex: 2,
          child: PurchaseCartPanel(),
        ),
      ],
    );
  }

  Future<void> _handleTap(BuildContext context, WidgetRef ref, ProductModel product) async {
    final result = product.isImeiTracked
        ? await showDialog<PurchaseCartItem>(
            context: context,
            builder: (_) => AddImeiPurchaseLineDialog(product: product),
          )
        : await showDialog<PurchaseCartItem>(
            context: context,
            builder: (_) => AddPurchaseLineDialog(product: product),
          );

    if (result != null) {
      ref.read(purchaseCartProvider.notifier).addLine(result);
    }
  }
}
