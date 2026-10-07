import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/categories/data/categories_provider.dart';
import 'package:mobile_shop_management_system/features/products/data/products_provider.dart';
import 'package:mobile_shop_management_system/features/products/models/product_model.dart';

/// Returns a ProductModel (without id if adding) via Navigator.pop,
/// or null if cancelled.
class ProductFormDialog extends ConsumerStatefulWidget {
  final ProductModel? existing;

  const ProductFormDialog({super.key, this.existing});

  @override
  ConsumerState<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;
  final _barcodeFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();
  int? _selectedCategoryId;
  late bool _isImeiTracked;

  // Set when the entered/scanned barcode matches a different existing
  // product — shown as a warning, doesn't block typing but does block submit.
  String? _barcodeWarning;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _barcodeController = TextEditingController(text: existing?.barcode ?? '');
    _priceController = TextEditingController(text: existing?.price.toString() ?? '');
    _quantityController = TextEditingController(text: existing?.quantity.toString() ?? '');
    _selectedCategoryId = existing?.categoryId;
    _isImeiTracked = existing?.isImeiTracked ?? false;

    // Check for a duplicate as soon as the barcode field loses focus —
    // covers both manual typing (tab/click away) and a scan (which we also
    // check explicitly on submit, since a scanner's Enter moves focus away
    // via onFieldSubmitted below, which also loses focus and triggers this).
    _barcodeFocusNode.addListener(() {
      if (!_barcodeFocusNode.hasFocus) {
        _checkBarcodeDuplicate();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _barcodeFocusNode.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBarcodeDuplicate() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      if (mounted) setState(() => _barcodeWarning = null);
      return;
    }

    final repo = ref.read(productsRepositoryProvider);
    final existingProduct = await repo.getByBarcode(barcode);

    if (!mounted) return;

    final isDifferentProduct =
        existingProduct != null && existingProduct.id != widget.existing?.id;

    setState(() {
      _barcodeWarning =
          isDifferentProduct ? 'Already used by "${existingProduct.name}"' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Text(isEdit ? 'Edit Product' : 'Add Product'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text(
                      'No categories yet — add one in the Categories tab first.',
                      style: TextStyle(color: Colors.red),
                    );
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                    validator: (v) => v == null ? 'Category is required' : null,
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Error loading categories: $e'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcodeController,
                focusNode: _barcodeFocusNode,
                decoration: InputDecoration(
                  labelText: 'Barcode (optional — type or scan)',
                  suffixIcon: const Icon(Icons.qr_code_scanner, size: 20),
                  errorText: _barcodeWarning,
                ),
                textInputAction: TextInputAction.next,
                // A scanner sends Enter after the digits. Don't submit the
                // whole form here — just check for a duplicate and move to
                // the next field, same as a cashier tabbing through.
                onFieldSubmitted: (_) {
                  _checkBarcodeDuplicate();
                  FocusScope.of(context).requestFocus(_priceFocusNode);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      focusNode: _priceFocusNode,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: _validatePrice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      enabled: !_isImeiTracked,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        helperText: _isImeiTracked ? 'Added via Inventory' : null,
                      ),
                      keyboardType: TextInputType.number,
                      validator: _isImeiTracked ? null : _validateQuantity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('IMEI / Serial tracked'),
                subtitle: Text(
                  isEdit
                      ? 'Cannot be changed after creation.'
                      : 'For phones or serialized items. Stock is added one unit '
                          'at a time (with its IMEI) via Inventory, not as a plain number.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: _isImeiTracked,
                onChanged: isEdit
                    ? null
                    : (value) => setState(() {
                          _isImeiTracked = value ?? false;
                          if (_isImeiTracked) _quantityController.text = '0';
                        }),
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
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Price is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid number';
    if (parsed < 0) return 'Price cannot be negative';
    return null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Quantity is required';
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Enter a whole number';
    if (parsed < 0) return 'Quantity cannot be negative';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return; // dropdown validator already caught this

    // Final authoritative duplicate check right before submit, in case the
    // field never lost focus (e.g. Enter wasn't used and Add was clicked
    // directly after typing).
    await _checkBarcodeDuplicate();
    if (_barcodeWarning != null) return;

    final product = ProductModel(
      id: widget.existing?.id,
      categoryId: _selectedCategoryId!,
      name: _nameController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      // IMEI-tracked products always start at 0 — stock comes in via
      // Inventory's per-IMEI stock-in, not this form.
      quantity: _isImeiTracked ? (widget.existing?.quantity ?? 0) : int.parse(_quantityController.text.trim()),
      isImeiTracked: _isImeiTracked,
    );
    if (mounted) Navigator.of(context).pop(product);
  }
}
