import 'package:share_plus/share_plus.dart';

Future<void> sharePdf(String filePath) async {
  final result = await Share.shareXFiles(
    [XFile(filePath)],
    text: 'Voici mon timesheet',
  );

  if (result.status == ShareResultStatus.success) {
    print('PDF partagé avec succès');
  }
}