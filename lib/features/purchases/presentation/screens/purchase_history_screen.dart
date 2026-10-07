import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:mobile_shop_management_system/features/purchases/data/purchases_provider.dart';

class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(purchaseHistoryProvider);
    final dateFormat = DateFormat.yMd().add_jm();

    return historyAsync.when(
      data: (purchases) {
        if (purchases.isEmpty) {
          return const Center(child: Text('No purchases yet.'));
        }
        return ListView.separated(
          itemCount: purchases.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = purchases[index];
            return ListTile(
              leading: const Icon(Icons.local_shipping_outlined),
              title: Text('Purchase #${p.purchaseId} · \$${p.total.toStringAsFixed(2)}'),
              subtitle: Text(
                '${p.supplierName} · ${p.username} · ${dateFormat.format(p.createdAt)}',
              ),
              trailing: Text('${p.itemCount} unit(s)'),
              onTap: () => _showDetail(context, ref, p.purchaseId),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
    );
  }

  Future<void> _showDetail(BuildContext context, WidgetRef ref, int purchaseId) async {
    final repo = ref.read(purchasesRepositoryProvider);
    final detail = await repo.getDetail(purchaseId);
    if (detail == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Purchase #${detail.purchaseId}'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Supplier: ${detail.supplierName}'),
              Text('Received by: ${detail.username}'),
              if (detail.notes != null) Text('Notes: ${detail.notes}'),
              const Divider(),
              ...detail.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('${item.productName} × ${item.quantity}')),
                      Text('\$${item.subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '\$${detail.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
