import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/backup/backup_provider.dart';
import '../../../../core/backup/backup_service.dart';

class BackupRestoreSection extends ConsumerStatefulWidget {
  const BackupRestoreSection({super.key});

  @override
  ConsumerState<BackupRestoreSection> createState() => _BackupRestoreSectionState();
}

class _BackupRestoreSectionState extends ConsumerState<BackupRestoreSection> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Backup & Restore', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Save a copy of your entire database, or restore from a previous backup.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Backup Now'),
                    onPressed: _working ? null : _handleBackup,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore from Backup'),
                    onPressed: _working ? null : _handleRestore,
                  ),
                ),
              ],
            ),
            if (_working) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleBackup() async {
    final backupService = ref.read(backupServiceProvider);
    final suggestedName = backupService.suggestedBackupFilename();

    final destinationPath = await FilePicker.saveFile(
      dialogTitle: 'Save Database Backup',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (destinationPath == null) return; // cancelled

    setState(() => _working = true);
    try {
      await backupService.backupToFile(destinationPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to $destinationPath'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on BackupException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _handleRestore() async {
    final result = await FilePicker.pickFiles(
      dialogTitle: 'Select Backup File',
      type: FileType.custom,
      allowedExtensions: ['db'],
    );
    if (result == null || result.files.single.path == null) return; // cancelled
    final sourcePath = result.files.single.path!;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace ALL current data — products, sales, users, everything — '
          'with the contents of the selected backup file. This cannot be undone from '
          'within the app. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _working = true);
    final backupService = ref.read(backupServiceProvider);
    try {
      await backupService.restoreFromFile(sourcePath);
      if (mounted) _showRestartPrompt();
    } on BackupException catch (e) {
      if (mounted) _showError(e.message);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _showRestartPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Restore Complete'),
        content: const Text(
          'The database has been restored. The app needs to be restarted for the '
          'restored data to show up correctly everywhere.',
        ),
        actions: [
          FilledButton(
            onPressed: () => exit(0),
            child: const Text('Close App Now'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
