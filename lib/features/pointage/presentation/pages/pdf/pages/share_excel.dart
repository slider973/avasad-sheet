import 'package:share_plus/share_plus.dart';

Future<void> shareExcel(String filePath) async {
  // Extraire le nom du fichier pour obtenir le mois et l'année
  final fileName = filePath.split('/').last.replaceAll('.xlsx', '');
  
  // Le nom du fichier est au format "timesheet_mois_année" (ex: timesheet_novembre_2024)
  String shareText = 'Voici ma timesheet en format Excel';
  
  // Extraire le mois et l'année du nom du fichier
  if (fileName.startsWith('timesheet_')) {
    final datePart = fileName.replaceFirst('timesheet_', '');
    final parts = datePart.split('_');
    if (parts.length >= 2) {
      final month = parts[0];
      final year = parts[1];
      // Capitaliser la première lettre du mois
      final monthCapitalized = month[0].toUpperCase() + month.substring(1);
      shareText = 'Timesheet Excel - $monthCapitalized $year';
    }
  }
  
  final result = await Share.shareXFiles(
    [XFile(filePath)],
    text: shareText,
  );

  if (result.status == ShareResultStatus.success) {
    print('Excel partagé avec succès');
  }
}