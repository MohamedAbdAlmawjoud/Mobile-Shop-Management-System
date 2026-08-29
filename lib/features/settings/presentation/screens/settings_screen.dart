import 'package:flutter/material.dart';

import '../../../users/presentation/screens/users_management_section.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UsersManagementSection(),
            // Future settings sections (backup/restore, app preferences, etc.)
            // go here as additional cards, once Step 15 covers them.
          ],
        ),
      ),
    );
  }
}
