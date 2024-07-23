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

    String? selectedDirectory;
    if (Platform.isWindows) {
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        throw Exception('No directory selected');
      }
    } else {
      final directory = await getExternalStorageDirectory();
      selectedDirectory = directory?.path;
      if (selectedDirectory == null) {
        throw Exception('Could not access external storage');
      }
    }

    final isar = await getIsarInstance();
    final backupFileName = 'isar_backup_${DateTime.now().millisecondsSinceEpoch}.isar';
    final backupPath = path.join(selectedDirectory, backupFileName);

    await isar.copyToFile(backupPath);

    return backupPath;
  }

  Future<bool> importDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Import is not supported on web platform');
    }

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['isar'],
    );

    if (result != null && result.files.single.path != null) {
      String importPath = result.files.single.path!;
      File importFile = File(importPath);

      if (!await importFile.exists()) {
        throw Exception('Selected file does not exist');
      }

      final isar = await getIsarInstance();
      final dbPath = isar.path;

      // Fermer l'instance Isar
      await closeIsarInstance();
      await closeIsarInstance();

      try {
        // Supprimer le fichier de base de données existant s'il existe
        if (await File(dbPath!).exists()) {
          await File(dbPath).delete();
        }

        // Copier le fichier de sauvegarde vers l'emplacement de la base de données
        await importFile.copy(dbPath);

        // Rouvrir l'instance Isar
        await reopenIsarInstance();

        return true;
      } catch (e) {
        // En cas d'erreur, essayer de rouvrir l'instance Isar
        await reopenIsarInstance();
        throw Exception('Error during import: $e');
      }
    } else {
      throw Exception('No file selected');
    }
  }
}