import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/suppliers/data/suppliers_provider.dart';
import 'package:mobile_shop_management_system/features/suppliers/models/supplier_model.dart';
import 'package:mobile_shop_management_system/features/suppliers/presentation/widgets/supplier_form_dialog.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Supplier',
            onPressed: () => _handleAdd(context, ref),
          ),
        ],
      ),
      body: suppliersAsync.when(
        data: (suppliers) {
          if (suppliers.isEmpty) {
            return const Center(child: Text('No suppliers yet. Tap + to add one.'));
          }
          return ListView.separated(
            itemCount: suppliers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final supplier = suppliers[index];
              final details = [
                if (supplier.phone != null) supplier.phone!,
                if (supplier.email != null) supplier.email!,
              ].join(' · ');
              return ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text(supplier.name),
                subtitle: details.isEmpty ? null : Text(details),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _handleEdit(context, ref, supplier),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _handleDelete(context, ref, supplier),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error loading suppliers: $error')),
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context, WidgetRef ref) async {
    final supplier = await showDialog<SupplierModel>(
      context: context,
      builder: (_) => const SupplierFormDialog(),
    );
    if (supplier == null) return;

    try {
      await ref.read(suppliersProvider.notifier).addSupplier(supplier);
    } on SupplierOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _handleEdit(BuildContext context, WidgetRef ref, SupplierModel supplier) async {
    final updated = await showDialog<SupplierModel>(
      context: context,
      builder: (_) => SupplierFormDialog(existing: supplier),
    );
    if (updated == null) return;

    try {
      await ref.read(suppliersProvider.notifier).updateSupplier(updated);
    } on SupplierOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, SupplierModel supplier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Delete "${supplier.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(suppliersProvider.notifier).deleteSupplier(supplier.id!);
    } on SupplierOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
