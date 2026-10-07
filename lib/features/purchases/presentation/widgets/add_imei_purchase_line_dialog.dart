import 'package:flutter/material.dart';

import 'package:mobile_shop_management_system/features/products/models/product_model.dart';
import 'package:mobile_shop_management_system/features/purchases/data/purchase_cart_item.dart';

/// For IMEI-tracked products: unit cost applies to every unit in this
/// batch, plus one IMEI per line (scanner-friendly, same pattern as
/// Inventory's IMEI stock-in).
class AddImeiPurchaseLineDialog extends StatefulWidget {
  final ProductModel product;

  const AddImeiPurchaseLineDialog({super.key, required this.product});

  @override
  State<AddImeiPurchaseLineDialog> createState() => _AddImeiPurchaseLineDialogState();
}

class _AddImeiPurchaseLineDialogState extends State<AddImeiPurchaseLineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _costController = TextEditingController();
  final _imeisController = TextEditingController();

  @override
  void dispose() {
    _costController.dispose();
    _imeisController.dispose();
    super.dispose();
  }

  List<String> _parseLines(String text) {
    return text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Receive (IMEI) — ${widget.product.name}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _costController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Unit cost (applies to each unit)'),
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').trim());
                  if (parsed == null || parsed < 0) return 'Enter a valid cost';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan or type one IMEI per line:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imeisController,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '123456789012345\n123456789012346\n...',
                ),
                validator: (v) {
                  final lines = _parseLines(v ?? '');
                  if (lines.isEmpty) return 'Enter at least one IMEI';
                  if (lines.toSet().length != lines.length) return 'Duplicate IMEI in this list';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final imeis = _parseLines(_imeisController.text);
    Navigator.of(context).pop(PurchaseCartItem(
      product: widget.product,
      quantity: imeis.length,
      unitCost: double.parse(_costController.text.trim()),
      imeis: imeis,
    ));
  }
}
