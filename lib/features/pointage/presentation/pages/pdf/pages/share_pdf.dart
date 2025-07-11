import 'package:share_plus/share_plus.dart';

Future<void> sharePdf(String filePath) async {
  // Extraire le nom du fichier pour obtenir le mois et l'année
  final fileName = filePath.split('/').last.replaceAll('.pdf', '');
  
  // Le nom du fichier est au format "mois_année" (ex: novembre_2024)
  String shareText = 'Voici ma timesheet';
  
  // Extraire le mois et l'année du nom du fichier
  final parts = fileName.split('_');
  if (parts.length >= 2) {
    final month = parts[0];
    final year = parts[1];
    // Capitaliser la première lettre du mois
    final monthCapitalized = month[0].toUpperCase() + month.substring(1);
    shareText = 'Timesheet du mois de $monthCapitalized $year';
  } else if (parts.length == 1) {
    // Si le format est différent, utiliser le nom complet
    final nameCapitalized = fileName[0].toUpperCase() + fileName.substring(1);
    shareText = 'Timesheet - $nameCapitalized';
  }
  
  final result = await Share.shareXFiles(
    [XFile(filePath)],
    text: shareText,
  );

  if (result.status == ShareResultStatus.success) {
    print('PDF partagé avec succès');
  }
}
