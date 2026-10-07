import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/products/data/imei_provider.dart';
import 'package:mobile_shop_management_system/features/products/models/product_model.dart';

/// Lets the cashier pick (or scan) the specific in-stock IMEI being sold.
/// Returns the chosen IMEI string, or null if cancelled.
class SelectImeiDialog extends ConsumerStatefulWidget {
  final ProductModel product;

  const SelectImeiDialog({super.key, required this.product});

  @override
  ConsumerState<SelectImeiDialog> createState() => _SelectImeiDialogState();
}

class _SelectImeiDialogState extends ConsumerState<SelectImeiDialog> {
  final _scanController = TextEditingController();

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imeisAsync = ref.watch(productImeisProvider(widget.product.id!));

    return AlertDialog(
      title: Text('Select Unit — ${widget.product.name}'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _scanController,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.qr_code_scanner),
                labelText: 'Scan IMEI',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (value) => Navigator.of(context).pop(value.trim()),
            ),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('Or pick from in-stock units:')),
            const Divider(),
            Expanded(
              child: imeisAsync.when(
                data: (imeis) {
                  final inStock = imeis.where((i) => i.isInStock).toList();
                  if (inStock.isEmpty) {
                    return const Center(child: Text('No units in stock.'));
                  }
                  return ListView.builder(
                    itemCount: inStock.length,
                    itemBuilder: (context, index) {
                      final imei = inStock[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.smartphone_outlined),
                        title: Text(imei.imei),
                        onTap: () => Navigator.of(context).pop(imei.imei),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
