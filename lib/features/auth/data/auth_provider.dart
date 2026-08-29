import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/password_hasher.dart';
import '../../users/data/users_provider.dart';
import '../../users/models/user_model.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

/// Holds the currently logged-in user, or null if nobody is logged in.
/// MobileShopApp watches this to decide: setup screen / login screen / main app.
class AuthNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  Future<void> login(String username, String password) async {
    final repo = ref.read(usersRepositoryProvider);
    final user = await repo.getByUsername(username.trim());

    if (user == null || !PasswordHasher.verify(password, user.passwordHash)) {
      throw const AuthException('Invalid username or password.');
    }
    state = user;
  }

  /// Used only during first-run setup, when no users exist yet.
  Future<void> createFirstAdmin(String username, String password) async {
    final repo = ref.read(usersRepositoryProvider);
    if (username.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Username and password are required.');
    }
    final user = await repo.insert(UserModel(
      username: username.trim(),
      passwordHash: PasswordHasher.hash(password),
      role: 'admin',
    ));
    state = user;
  }

  void logout() {
    state = null;
  }
}

final authProvider = NotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

/// True once we've checked whether any users exist at all (first run vs not).
/// Used to decide between the "create admin" setup screen and the login screen.
final hasAnyUsersProvider = FutureProvider<bool>((ref) async {
  final repo = ref.read(usersRepositoryProvider);
  return repo.hasAnyUsers();
});
