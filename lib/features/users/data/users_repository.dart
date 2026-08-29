import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_service.dart';
import '../models/user_model.dart';

class UsersRepository {
  Future<Database> get _db async => DatabaseService.instance.database;

  Future<List<UserModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('users', orderBy: 'username ASC');
    return rows.map(UserModel.fromMap).toList();
  }

  Future<UserModel?> getByUsername(String username) async {
    final db = await _db;
    final rows = await db.query('users', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<bool> hasAnyUsers() async {
    final db = await _db;
    final result = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM users'),
    );
    return (result ?? 0) > 0;
  }

  Future<UserModel> insert(UserModel user) async {
    final db = await _db;
    final id = await db.insert('users', user.toMap());
    return user.copyWith(id: id);
  }

  Future<void> update(UserModel user) async {
    if (user.id == null) throw ArgumentError('Cannot update a user with no id');
    final db = await _db;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}
