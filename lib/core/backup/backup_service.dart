import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/database_service.dart';

class BackupException implements Exception {
  final String message;
  const BackupException(this.message);
}

/// Handles copying the live SQLite database out to a backup file, and
/// replacing it with a chosen backup file on restore.
///
/// Both operations close the live database connection first (SQLite on
/// desktop holds an exclusive-ish file handle; copying or overwriting the
/// file while it's open risks a corrupt or incomplete copy) and reopen it
/// afterward via DatabaseService, which lazily reconnects on next access.
class BackupService {
  /// Copies the current database to [destinationPath]. Returns the path
  /// written to.
  Future<String> backupToFile(String destinationPath) async {
    await DatabaseService.instance.close();

    final sourcePath = await DatabaseService.instance.dbFilePath;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw const BackupException('No database file found to back up.');
    }

    await sourceFile.copy(destinationPath);

    // Reopen so the app keeps working normally after the backup completes.
    await DatabaseService.instance.database;

    return destinationPath;
  }

  /// Replaces the current database with the one at [sourcePath].
  ///
  /// Validates the source file is actually a usable copy of this app's
  /// database (has the expected tables) before touching anything — a bad
  /// or unrelated file is rejected with nothing overwritten. The current
  /// database is also saved as a safety copy alongside itself before the
  /// swap, in case the "restore" needs to be undone manually.
  Future<void> restoreFromFile(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw const BackupException('Selected backup file does not exist.');
    }

    await _validateIsUsableDatabase(sourcePath);

    await DatabaseService.instance.close();

    final currentPath = await DatabaseService.instance.dbFilePath;
    final currentFile = File(currentPath);

    // Keep a safety copy of what's being replaced.
    if (await currentFile.exists()) {
      final safetyPath = '$currentPath.before_restore';
      await currentFile.copy(safetyPath);
    }

    await sourceFile.copy(currentPath);

    // Reopen on the restored file.
    await DatabaseService.instance.database;
  }

  Future<void> _validateIsUsableDatabase(String path) async {
    try {
      sqfliteFfiInit();
      final testDb = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(readOnly: true),
      );
      final tables = await testDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users','products','sales')",
      );
      await testDb.close();

      if (tables.length < 3) {
        throw const BackupException(
          'That file doesn\'t look like a Mobile Shop backup (missing expected tables).',
        );
      }
    } on BackupException {
      rethrow;
    } catch (e) {
      throw const BackupException(
        'Could not read that file as a database. It may be corrupted or not a valid backup.',
      );
    }
  }

  /// Suggested filename for a new backup, e.g. mobile_shop_backup_2026-08-30.db
  String suggestedBackupFilename() {
    final now = DateTime.now();
    final date =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final time = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    return 'mobile_shop_backup_${date}_$time.db';
  }
}
