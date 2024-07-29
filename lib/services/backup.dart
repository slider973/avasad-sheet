import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:time_sheet/services/logger_service.dart';

class BackupService {
  final Future<Isar> Function() getIsarInstance;
  final Future<void> Function() closeIsarInstance;
  final Future<Isar> Function() reopenIsarInstance;

  BackupService({
    required this.getIsarInstance,
    required this.closeIsarInstance,
    required this.reopenIsarInstance,
  });

  Future<ShareResult> backupDatabase() async {
    late final Isar isar;
    try {
      if (kIsWeb) {
        throw UnsupportedError('Backup is not supported on web platform');
      }

      isar = await getIsarInstance();
      final backupFileName = 'isar_backup_${DateTime.now().millisecondsSinceEpoch}.isar';

      // Get the app's temporary directory
      final tempDir = await getTemporaryDirectory();
      final backupPath = path.join(tempDir.path, backupFileName);
      final sourcePath = isar.path!;

      // Close the database before backup
      await closeIsarInstance();

      try {
        // Perform the backup
        await File(sourcePath).copy(backupPath);

        logger.i('Backup completed successfully: $backupPath');

        // Share the backup file
        final result = await Share.shareXFiles(
          [XFile(backupPath)],
          subject: 'Database Backup',
          text: 'Here is your database backup file.',
        );

        // Clean up the temporary file
        await File(backupPath).delete();

        return result;
      } catch (e) {
        logger.e('Error during file copy or sharing: $e');
        throw Exception('Failed to copy or share database file: $e');
      } finally {
        // Reopen the database
        await reopenIsarInstance();
      }
    } catch (e) {
      logger.e('Error during backup: $e');
      // Ensure we attempt to reopen the database even if an error occurred
      await reopenIsarInstance();
      throw Exception('Error during backup: $e');
    }
  }


  Future<bool> importDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Import is not supported on web platform');
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      String importPath = result.files.single.path!;
      File importFile = File(importPath);

      if (!await importFile.exists()) {
        throw Exception('Selected file does not exist');
      }

      final isar = await getIsarInstance();
      final dbPath = isar.path;

      await closeIsarInstance();

      try {
        if (await File(dbPath!).exists()) {
          await File(dbPath).delete();
        }

        await importFile.copy(dbPath);
        await reopenIsarInstance();

        return true;
      } catch (e) {
        await reopenIsarInstance();
        throw Exception('Error during import: $e');
      }
    } else {
      throw Exception('No file selected');
    }
  }
}
