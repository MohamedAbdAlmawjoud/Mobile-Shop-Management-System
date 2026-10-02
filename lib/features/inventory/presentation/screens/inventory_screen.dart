import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/inventory_provider.dart';
import '../../../products/data/imei_provider.dart';
import '../../../products/data/imei_repository.dart';
import '../../../products/models/product_model.dart';
import '../widgets/imei_stock_in_dialog.dart';
import '../widgets/stock_in_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current Stock'),
            Tab(text: 'Movement History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CurrentStockTab(),
          _MovementHistoryTab(),
        ],
      ),
    );
  }
}

class _CurrentStockTab extends ConsumerWidget {
  const _CurrentStockTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(inventoryProvider);

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(child: Text('No products yet.'));
        }
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final product = products[index];
            final lowStock = product.quantity <= 5;
            return ListTile(
              leading: Icon(
                lowStock ? Icons.warning_amber_rounded : Icons.inventory_2_outlined,
                color: lowStock ? Colors.orange : null,
              ),
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
              subtitle: Text('Current quantity: ${product.quantity}'),
              trailing: FilledButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Stock In'),
                onPressed: () => product.isImeiTracked
                    ? _handleImeiStockIn(context, ref, product)
                    : _handleStockIn(context, ref, product),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading inventory: $e')),
    );
  }

  Future<void> _handleStockIn(BuildContext context, WidgetRef ref, ProductModel product) async {
    final result = await showDialog<StockInResult>(
      context: context,
      builder: (_) => StockInDialog(product: product),
    );
    if (result == null) return;

    try {
      await ref.read(inventoryProvider.notifier).stockIn(
            productId: product.id!,
            quantity: result.quantity,
            reason: result.reason,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${result.quantity} to ${product.name}.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on InventoryOperationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleImeiStockIn(BuildContext context, WidgetRef ref, ProductModel product) async {
    final result = await showDialog<ImeiStockInResult>(
      context: context,
      builder: (_) => ImeiStockInDialog(product: product),
    );
    if (result == null) return;

    try {
      await ref.read(imeiActionsProvider).stockIn(
            productId: product.id!,
            imeis: result.imeis,
            reason: result.reason,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${result.imeis.length} unit(s) to ${product.name}.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on ImeiOperationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _MovementHistoryTab extends ConsumerWidget {
  const _MovementHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(movementHistoryProvider(null));
    final dateFormat = DateFormat.yMd().add_jm();

    return historyAsync.when(
      data: (movements) {
        if (movements.isEmpty) {
          return const Center(child: Text('No stock movements yet.'));
        }
        return ListView.separated(
          itemCount: movements.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final m = movements[index];
            final isPositive = m.quantityChange > 0;
            return ListTile(
              leading: Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                color: isPositive ? Colors.green : Colors.red,
              ),
              title: Text('${m.productName} · ${m.type}'),
              subtitle: Text(
                '${m.username} · ${dateFormat.format(m.createdAt)}'
                '${m.reason != null ? ' · ${m.reason}' : ''}',
              ),
              trailing: Text(
                '${isPositive ? '+' : ''}${m.quantityChange}',
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error loading history: $e')),
    );
  }
}
