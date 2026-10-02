import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/imei_provider.dart';
import '../../data/imei_repository.dart';
import '../../models/product_model.dart';

class ViewImeisDialog extends ConsumerWidget {
  final ProductModel product;

  const ViewImeisDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imeisAsync = ref.watch(productImeisProvider(product.id!));
    final dateFormat = DateFormat.yMd();

    return AlertDialog(
      title: Text('IMEIs — ${product.name}'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: imeisAsync.when(
          data: (imeis) {
            if (imeis.isEmpty) {
              return const Center(
                child: Text('No IMEIs yet. Add stock via Inventory → Stock In.'),
              );
            }
            final inStock = imeis.where((i) => i.isInStock).toList();
            final sold = imeis.where((i) => !i.isInStock).toList();

            return ListView(
              children: [
                Text(
                  'In Stock (${inStock.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (inStock.isEmpty) const Text('None', style: TextStyle(color: Colors.grey)),
                ...inStock.map((imei) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                      title: Text(imei.imei),
                      subtitle: Text('Added ${dateFormat.format(imei.createdAt)}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        tooltip: 'Remove (typo/mistake)',
                        onPressed: () => _handleRemove(context, ref, imei.id),
                      ),
                    )),
                const Divider(height: 24),
                Text(
                  'Sold (${sold.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (sold.isEmpty) const Text('None', style: TextStyle(color: Colors.grey)),
                ...sold.map((imei) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.sell_outlined, color: Colors.grey),
                      title: Text(imei.imei),
                      subtitle: Text('Sale #${imei.saleId}'),
                    )),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _handleRemove(BuildContext context, WidgetRef ref, int imeiRowId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove IMEI'),
        content: const Text('Remove this unsold IMEI (e.g. it was a typo)? This reduces stock by 1.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(imeiActionsProvider).removeUnsold(imeiRowId, product.id!);
    } on ImeiOperationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}
