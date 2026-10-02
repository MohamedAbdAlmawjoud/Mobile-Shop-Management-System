import 'package:flutter/material.dart';

import '../../../products/models/product_model.dart';
import '../../data/purchase_cart_item.dart';

/// For regular (non-IMEI) products: quantity + unit cost.
class AddPurchaseLineDialog extends StatefulWidget {
  final ProductModel product;

  const AddPurchaseLineDialog({super.key, required this.product});

  @override
  State<AddPurchaseLineDialog> createState() => _AddPurchaseLineDialogState();
}

class _AddPurchaseLineDialogState extends State<AddPurchaseLineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Receive — ${widget.product.name}'),
      content: SizedBox(
        width: 340,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _quantityController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (v) {
                  final parsed = int.tryParse((v ?? '').trim());
                  if (parsed == null || parsed <= 0) return 'Enter a quantity greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _costController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Unit cost'),
                validator: (v) {
                  final parsed = double.tryParse((v ?? '').trim());
                  if (parsed == null || parsed < 0) return 'Enter a valid cost';
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
    Navigator.of(context).pop(PurchaseCartItem(
      product: widget.product,
      quantity: int.parse(_quantityController.text.trim()),
      unitCost: double.parse(_costController.text.trim()),
    ));
  }
}
