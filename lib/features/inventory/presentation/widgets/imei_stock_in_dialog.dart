import 'package:flutter/material.dart';

import 'package:mobile_shop_management_system/features/products/models/product_model.dart';

class ImeiStockInResult {
  final List<String> imeis;
  final String? reason;

  const ImeiStockInResult({required this.imeis, this.reason});
}

/// Stock-in for IMEI-tracked products: one IMEI per line instead of a
/// plain quantity number — each line becomes one unit in stock.
class ImeiStockInDialog extends StatefulWidget {
  final ProductModel product;

  const ImeiStockInDialog({super.key, required this.product});

  @override
  State<ImeiStockInDialog> createState() => _ImeiStockInDialogState();
}

class _ImeiStockInDialogState extends State<ImeiStockInDialog> {
  final _formKey = GlobalKey<FormState>();
  final _imeisController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _imeisController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Stock (IMEI) — ${widget.product.name}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current quantity: ${widget.product.quantity}'),
              const SizedBox(height: 12),
              const Text(
                'Scan or type one IMEI per line (scanner Enter moves to the '
                'next line automatically):',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imeisController,
                autofocus: true,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '123456789012345\n123456789012346\n...',
                ),
                validator: (v) {
                  final lines = _parseLines(v ?? '');
                  if (lines.isEmpty) return 'Enter at least one IMEI';
                  if (lines.toSet().length != lines.length) {
                    return 'Duplicate IMEI in this list';
                  }
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

  List<String> _parseLines(String text) {
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(ImeiStockInResult(
      imeis: _parseLines(_imeisController.text),
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
    ));
  }
}
