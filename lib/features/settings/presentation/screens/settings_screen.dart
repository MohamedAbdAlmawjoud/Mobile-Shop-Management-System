import 'package:flutter/material.dart';

import '../../../products/presentation/widgets/imei_lookup_section.dart';
import '../../../users/presentation/screens/users_management_section.dart';
import '../widgets/backup_restore_section.dart';

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
            ImeiLookupSection(),
            BackupRestoreSection(),
            // Future settings sections (app preferences, etc.) go here.
          ],
        ),
      ),
    );
  }
}
