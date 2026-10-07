import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_shop_management_system/features/suppliers/models/supplier_model.dart';
import 'suppliers_repository.dart';

final suppliersRepositoryProvider = Provider((ref) => SuppliersRepository());

class SupplierOperationException implements Exception {
  final String message;
  const SupplierOperationException(this.message);
}

class SuppliersNotifier extends AsyncNotifier<List<SupplierModel>> {
  SuppliersRepository get _repo => ref.read(suppliersRepositoryProvider);

  @override
  Future<List<SupplierModel>> build() async {
    return _repo.getAll();
  }

  Future<void> addSupplier(SupplierModel supplier) async {
    if (supplier.name.trim().isEmpty) {
      throw const SupplierOperationException('Supplier name is required.');
    }
    await _repo.insert(supplier);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateSupplier(SupplierModel supplier) async {
    if (supplier.name.trim().isEmpty) {
      throw const SupplierOperationException('Supplier name is required.');
    }
    await _repo.update(supplier);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteSupplier(int id) async {
    try {
      await _repo.delete(id);
      ref.invalidateSelf();
      await future;
    } on Exception catch (e) {
      if (e.toString().toLowerCase().contains('foreign key')) {
        throw const SupplierOperationException(
          'Cannot delete this supplier — it has purchase history.',
        );
      }
      rethrow;
    }
  }
}

final suppliersProvider = AsyncNotifierProvider<SuppliersNotifier, List<SupplierModel>>(
  SuppliersNotifier.new,
);
