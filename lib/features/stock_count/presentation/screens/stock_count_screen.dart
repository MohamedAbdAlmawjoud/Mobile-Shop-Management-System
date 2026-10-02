import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/stock_count_entry.dart';
import '../../data/stock_count_provider.dart';

class StockCountScreen extends ConsumerWidget {
  const StockCountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(stockCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Count'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Start a new count (discard current entries)',
            onPressed: () => ref.invalidate(stockCountProvider),
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(child: Text('No products to count.'));
          }
          final countedWithDiff = entries.where((e) => e.isCounted && e.difference != 0).length;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Colors.blue.withValues(alpha: 0.08),
                child: const Text(
                  'IMEI-tracked products aren\'t shown here — manage their stock '
                  'individually via Inventory → Stock In / Products → View IMEIs.',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Row(
                  children: const [
                    SizedBox(width: 12),
                    Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('System Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Actual Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                    Expanded(flex: 2, child: Text('Difference', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _StockCountRow(entry: entry);
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      countedWithDiff == 0
                          ? 'No differences to apply yet.'
                          : '$countedWithDiff product(s) have a counted difference.',
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: countedWithDiff == 0 ? null : () => _handleApprove(context, ref),
                      child: const Text('Approve & Apply Adjustments'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve Stock Count'),
        content: const Text(
          'This will update product quantities to match your counted amounts and '
          'record an adjustment for each difference. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final count = await ref.read(stockCountProvider.notifier).approve();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Applied $count adjustment(s).'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on StockCountException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _StockCountRow extends ConsumerStatefulWidget {
  final StockCountEntry entry;

  const _StockCountRow({required this.entry});

  @override
  ConsumerState<_StockCountRow> createState() => _StockCountRowState();
}

class _StockCountRowState extends ConsumerState<_StockCountRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.entry.actualQuantity?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final difference = entry.difference;

    Color? diffColor;
    String diffText = '—';
    if (difference != null) {
      diffText = difference > 0 ? '+$difference' : '$difference';
      diffColor = difference == 0 ? null : (difference < 0 ? Colors.red : Colors.green);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 0),
          Expanded(flex: 3, child: Text(entry.product.name)),
          Expanded(flex: 2, child: Text('${entry.systemQuantity}')),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                hintText: 'Count',
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value.trim());
                if (parsed != null && parsed >= 0) {
                  ref
                      .read(stockCountProvider.notifier)
                      .setActualQuantity(entry.product.id!, parsed);
                }
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              diffText,
              style: TextStyle(color: diffColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
