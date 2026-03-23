import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:time_sheet/core/services/storage/storage_service.dart';

Future<void> sharePdf(String filePath) async {
  // Extraire le nom du fichier pour obtenir le mois et l'année
  final fileName = filePath.split('/').last;
  final fileNameWithoutExt = fileName.replaceAll('.pdf', '');

  // Vérifier si le fichier existe, sinon le re-télécharger
  String actualPath = filePath;
  if (!File(filePath).existsSync()) {
    final bytes = await StorageService().downloadPdfByName(fileName);
    if (bytes != null && bytes.isNotEmpty) {
      final output = await getApplicationDocumentsDirectory();
      final localDir = '${output.path}/extract-time-sheet';
      await Directory(localDir).create(recursive: true);
      final localFile = File('$localDir/$fileName');
      await localFile.writeAsBytes(bytes);
      actualPath = localFile.path;
    } else {
      return;
    }
  }

  // Le nom du fichier est au format "mois_année" (ex: novembre_2024)
  String shareText = 'Voici ma timesheet';

  // Extraire le mois et l'année du nom du fichier
  final parts = fileNameWithoutExt.split('_');
  if (parts.length >= 2) {
    final month = parts[0];
    final year = parts[1];
    // Capitaliser la première lettre du mois
    final monthCapitalized = month[0].toUpperCase() + month.substring(1);
    shareText = 'Timesheet du mois de $monthCapitalized $year';
  } else if (parts.length == 1) {
    // Si le format est différent, utiliser le nom complet
    final nameCapitalized = fileNameWithoutExt[0].toUpperCase() + fileNameWithoutExt.substring(1);
    shareText = 'Timesheet - $nameCapitalized';
  }

  await Share.shareXFiles(
    [XFile(actualPath)],
    text: shareText,
  );
}
