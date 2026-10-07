import 'package:flutter/material.dart';

import 'package:mobile_shop_management_system/features/products/models/product_model.dart';

class StockInResult {
  final int quantity;
  final String? reason;

  const StockInResult({required this.quantity, this.reason});
}

class StockInDialog extends StatefulWidget {
  final ProductModel product;

  const StockInDialog({super.key, required this.product});

  @override
  State<StockInDialog> createState() => _StockInDialogState();
}

class _StockInDialogState extends State<StockInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Stock — ${widget.product.name}'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current quantity: ${widget.product.quantity}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity to add'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Quantity is required';
                  final parsed = int.tryParse(v.trim());
                  if (parsed == null) return 'Enter a whole number';
                  if (parsed <= 0) return 'Must be greater than zero';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Reason (optional)'),
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
          child: const Text('Add Stock'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(StockInResult(
      quantity: int.parse(_quantityController.text.trim()),
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
    ));
  }
}
