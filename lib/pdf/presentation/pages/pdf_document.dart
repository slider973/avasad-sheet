import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:time_sheet/services/logger_service.dart';

import '../../domain/use_cases/generate_date_usecase.dart';
import '../widgets/adaptive_boutton.dart';

Future<Uint8List> _loadImage() async {
  final byteData = await rootBundle.load('assets/images/logo-heytalent.png');
  return byteData.buffer.asUint8List();
}

class PdfDocument extends StatelessWidget {
  const PdfDocument({super.key});

  Future<void> generatePdf() async {
    logger.i('start generatedPdf');
    final fontData = await rootBundle.load("assets/fonts/helvetica.ttf");
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final tealPdfColor = PdfColor.fromInt(Colors.teal.value);

    // Charger l'image
    final imageBytes = await _loadImage();
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
      ),
    );
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                  width: 1), // Ajoute une bordure autour de l'en-tête
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Image(pw.MemoryImage(imageBytes), width: 140, height: 140),
                  pw.SizedBox(width: 10),
                  pw.Text("Note de temps",
                      style: const pw.TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ), // Espacement avant la table
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),  // Donne à la première colonne une flexibilité de 2 parts
              1: pw.FlexColumnWidth(2),  // Donne à la deuxième colonne une flexibilité de 3 parts
              2: pw.FlexColumnWidth(2),  // Donne à la deuxième colonne une flexibilité de 3 parts
              3: pw.FlexColumnWidth(3),  // Donne à la deuxième colonne une flexibilité de 3 parts
              // Vous pouvez ajuster les valeurs selon vos besoins ou utiliser FixedColumnWidth pour des tailles fixes
            },
            children: [
              pw.TableRow(
                verticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  pw.Text('Entreprise de Mission (company):', style:  pw.TextStyle(color: tealPdfColor)),
                  pw.Text('Avasad'),
                  pw.Text('Travailleur:'),
                  pw.Text('Jonathan LEMAINE'),
                ],
              ),
              // ... Ajoutez d'autres pw.TableRow pour les lignes supplémentaires ...
            ],
          ),
          pw.TableHelper.fromTextArray(
            context: context,
            data: <List<dynamic>>[
              <dynamic>[
                '',
                ' ',
                ' Mois:',
                'fevrier-2023'
              ],
              // Ajoutez ici les données dynamiques pour chaque ligne
            ],
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
              children: [
                pw.Text('Signature Employé'),
                pw.Text('Signature Directeur'),
              ],
            ),
          ),
        ],
      ),
    );
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/exemple.pdf');
    logger.i('end generatedPdf ${directory.path}/exemple.pdf');
    await file.writeAsBytes(await pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Generator"),
      ),
      body: Center(
        child: AdaptiveButton(
          onPressed: () {
            generatePdf(); // Générer le PDF
            List<String> dates = generateDateList(2022, 11);
            print(dates);
          },
          text: 'Générer PDF', // Texte du bouton
        ),
      ),
    );
  }
}
