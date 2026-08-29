import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/password_hasher.dart';
import '../../auth/data/auth_provider.dart';
import '../models/user_model.dart';
import 'users_repository.dart';

final usersRepositoryProvider = Provider((ref) => UsersRepository());

class UserOperationException implements Exception {
  final String message;
  const UserOperationException(this.message);
}

class UsersNotifier extends AsyncNotifier<List<UserModel>> {
  UsersRepository get _repo => ref.read(usersRepositoryProvider);

  @override
  Future<List<UserModel>> build() async {
    return _repo.getAll();
  }

  Future<void> addUser({
    required String username,
    required String password,
    required String role,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      throw const UserOperationException('Username is required.');
    }
    if (password.length < 4) {
      throw const UserOperationException('Password must be at least 4 characters.');
    }
    if (await _repo.getByUsername(trimmedUsername) != null) {
      throw const UserOperationException('A user with this username already exists.');
    }

    await _repo.insert(UserModel(
      username: trimmedUsername,
      passwordHash: PasswordHasher.hash(password),
      role: role,
    ));
    ref.invalidateSelf();
    await future;
  }

  /// Password is optional here — leave blank to keep the existing password.
  Future<void> updateUser({
    required UserModel existing,
    required String username,
    required String role,
    String? newPassword,
  }) async {
    final trimmedUsername = username.trim();
    if (trimmedUsername.isEmpty) {
      throw const UserOperationException('Username is required.');
    }
    final clash = await _repo.getByUsername(trimmedUsername);
    if (clash != null && clash.id != existing.id) {
      throw const UserOperationException('A user with this username already exists.');
    }
    if (newPassword != null && newPassword.isNotEmpty && newPassword.length < 4) {
      throw const UserOperationException('Password must be at least 4 characters.');
    }

    // Prevent removing the last admin's own admin rights.
    if (existing.role == 'admin' && role != 'admin') {
      final all = state.value ?? [];
      final otherAdmins = all.where((u) => u.role == 'admin' && u.id != existing.id);
      if (otherAdmins.isEmpty) {
        throw const UserOperationException(
          'Cannot change role — at least one Admin account must remain.',
        );
      }
    }

    final updated = existing.copyWith(
      username: trimmedUsername,
      role: role,
      passwordHash: (newPassword != null && newPassword.isNotEmpty)
          ? PasswordHasher.hash(newPassword)
          : existing.passwordHash,
    );
    await _repo.update(updated);
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteUser(UserModel target) async {
    final currentUser = ref.read(authProvider);
    if (currentUser?.id == target.id) {
      throw const UserOperationException('You cannot delete your own account while logged in.');
    }

    if (target.role == 'admin') {
      final all = state.value ?? [];
      final otherAdmins = all.where((u) => u.role == 'admin' && u.id != target.id);
      if (otherAdmins.isEmpty) {
        throw const UserOperationException('Cannot delete the last remaining Admin account.');
      }
    }

    try {
      await _repo.delete(target.id!);
      ref.invalidateSelf();
      await future;
    } on Exception catch (e) {
      if (e.toString().toLowerCase().contains('foreign key')) {
        throw const UserOperationException(
          'Cannot delete this user — they have sales or stock history on record.',
        );
      }
      rethrow;
    }
  }
}

final usersProvider = AsyncNotifierProvider<UsersNotifier, List<UserModel>>(UsersNotifier.new);
