import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_provider.dart';
import '../../data/users_provider.dart';
import '../../models/user_model.dart';
import '../widgets/user_form_dialog.dart';

/// Embedded inside the Settings screen (not its own sidebar item) since
/// the plan groups user management under general app settings.
class UsersManagementSection extends ConsumerWidget {
  const UsersManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final currentUser = ref.watch(authProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Users', style: Theme.of(context).textTheme.titleLarge),
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Add User'),
                  onPressed: () => _handleAdd(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            usersAsync.when(
              data: (users) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  final isSelf = user.id == currentUser?.id;
                  return ListTile(
                    leading: Icon(
                      user.isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
                    ),
                    title: Text(user.username + (isSelf ? ' (you)' : '')),
                    subtitle: Text(user.role),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _handleEdit(context, ref, user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: isSelf ? null : () => _handleDelete(context, ref, user),
                        ),
                      ],
                    ),
                  );
                },
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Error loading users: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdd(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<UserFormResult>(
      context: context,
      builder: (_) => const UserFormDialog(),
    );
    if (result == null) return;

    try {
      await ref.read(usersProvider.notifier).addUser(
            username: result.username,
            password: result.password ?? '',
            role: result.role,
          );
    } on UserOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _handleEdit(BuildContext context, WidgetRef ref, UserModel user) async {
    final result = await showDialog<UserFormResult>(
      context: context,
      builder: (_) => UserFormDialog(existing: user),
    );
    if (result == null) return;

    try {
      await ref.read(usersProvider.notifier).updateUser(
            existing: user,
            username: result.username,
            role: result.role,
            newPassword: result.password,
          );
    } on UserOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete "${user.username}"? This cannot be undone.'),
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
      await ref.read(usersProvider.notifier).deleteUser(user);
    } on UserOperationException catch (e) {
      if (context.mounted) _showError(context, e.message);
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
