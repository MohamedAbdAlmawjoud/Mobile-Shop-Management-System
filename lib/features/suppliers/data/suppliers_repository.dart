import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mobile_shop_management_system/core/database/database_service.dart';
import 'package:mobile_shop_management_system/features/suppliers/models/supplier_model.dart';

class SuppliersRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  Future<List<SupplierModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('suppliers', orderBy: 'name ASC');
    return rows.map(SupplierModel.fromMap).toList();
  }

  Future<SupplierModel> insert(SupplierModel supplier) async {
    final db = await _db;
    final id = await db.insert('suppliers', supplier.toMap());
    return supplier.copyWith(id: id);
  }

  Future<void> update(SupplierModel supplier) async {
    if (supplier.id == null) {
      throw ArgumentError('Cannot update a supplier with no id');
    }
    final db = await _db;
    await db.update('suppliers', supplier.toMap(), where: 'id = ?', whereArgs: [supplier.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }
}
