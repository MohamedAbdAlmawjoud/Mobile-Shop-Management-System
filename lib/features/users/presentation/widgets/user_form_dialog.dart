import 'package:flutter/material.dart';

import '../../models/user_model.dart';

/// Result passed back via Navigator.pop when the form is submitted.
class UserFormResult {
  final String username;
  final String role;
  final String? password; // null/empty in edit mode means "keep existing"

  const UserFormResult({required this.username, required this.role, this.password});
}

class UserFormDialog extends StatefulWidget {
  final UserModel? existing;

  const UserFormDialog({super.key, this.existing});

  @override
  State<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late String _role;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.existing?.username ?? '');
    _passwordController = TextEditingController();
    _role = widget.existing?.role ?? 'cashier';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit User' : 'Add User'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _usernameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Username is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: isEdit ? 'New password (leave blank to keep current)' : 'Password',
                ),
                validator: (v) {
                  if (!isEdit && (v == null || v.length < 4)) {
                    return 'Password must be at least 4 characters';
                  }
                  if (isEdit && v != null && v.isNotEmpty && v.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                ],
                onChanged: (value) => setState(() => _role = value ?? _role),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(UserFormResult(
      username: _usernameController.text.trim(),
      role: _role,
      password: _passwordController.text.isEmpty ? null : _passwordController.text,
    ));
  }
}
