import 'dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as path;

class BackupService {
  final Future<Isar> Function() getIsarInstance;
  final Future<void> Function() closeIsarInstance;
  final Future<Isar> Function() reopenIsarInstance;

  BackupService({
    required this.getIsarInstance,
    required this.closeIsarInstance,
    required this.reopenIsarInstance,
  });

  Future<String> backupDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Backup is not supported on web platform');
    }

    final isar = await getIsarInstance();
    final backupFileName = 'isar_backup_${DateTime.now().millisecondsSinceEpoch}.isar';

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      throw Exception('No directory selected');
    }

    final backupPath = path.join(selectedDirectory, backupFileName);
    await isar.copyToFile(backupPath);

    return backupPath;
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