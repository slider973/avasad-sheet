import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../repositories/timesheet_repository.dart';
import '../../domain/entities/generated_pdf.dart';
import '../../../preference/domain/entities/user.dart';

class GenerateExcelUseCase {
  final TimesheetRepository repository;

  GenerateExcelUseCase(this.repository);

  Future<File> execute(int monthNumber, User user) async {
    try {
      // Récupérer les entrées du mois
      final entries = await repository.findEntriesFromMonthOf(
        monthNumber,
        DateTime.now().year,
      );

      // Créer le fichier Excel
      final excel = Excel.createExcel();

      // Supprimer la feuille par défaut si elle existe
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Créer une nouvelle feuille
      final sheet = excel['Timesheet'];

      // Ajouter les en-têtes
      sheet.appendRow([
        TextCellValue('Date'),
        TextCellValue('Jour'),
        TextCellValue('Entrée matin'),
        TextCellValue('Sortie matin'),
        TextCellValue('Entrée après-midi'),
        TextCellValue('Sortie après-midi'),
        TextCellValue('Total heures'),
        TextCellValue('Absence'),
      ]);

      // Style pour les en-têtes
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue300,
        horizontalAlign: HorizontalAlign.Center,
      );

      // Appliquer le style aux en-têtes
      for (int i = 0; i < 8; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = headerStyle;
      }

      // Vérifier qu'on a des données
      print('Nombre d\'entrées à exporter: ${entries.length}');

      // Ajouter les données
      for (var entry in entries) {
        final date = DateFormat('dd-MMM-yy').parse(entry.dayDate);
        final formattedDate = DateFormat('dd/MM/yyyy').format(date);

        // Calculer le total d'heures
        final totalHours = entry.calculateDailyTotal();
        final hours = totalHours.inHours;
        final minutes = totalHours.inMinutes.remainder(60);
        final totalFormatted = '${hours}h${minutes.toString().padLeft(2, '0')}';

        sheet.appendRow([
          TextCellValue(formattedDate),
          TextCellValue(_getDayName(date.weekday)),
          TextCellValue(entry.startMorning),
          TextCellValue(entry.endMorning),
          TextCellValue(entry.startAfternoon),
          TextCellValue(entry.endAfternoon),
          TextCellValue(totalFormatted),
          TextCellValue(entry.absenceReason ?? ''),
        ]);
      }

      // Ajouter une ligne de total
      final totalRow = sheet.maxRows;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow),
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: totalRow),
      );
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: totalRow))
        ..value = TextCellValue('Total du mois')
        ..cellStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Right);

      // Calculer le total mensuel
      final totalMonthHours = entries.fold<Duration>(
        Duration.zero,
        (total, entry) => total + entry.calculateDailyTotal(),
      );
      final totalHours = totalMonthHours.inHours;
      final totalMinutes = totalMonthHours.inMinutes.remainder(60);

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: totalRow))
        ..value = TextCellValue('${totalHours}h${totalMinutes.toString().padLeft(2, '0')}')
        ..cellStyle = CellStyle(bold: true);

      // Ajouter les informations utilisateur
      final infoRow = totalRow + 2;
      sheet.appendRow([TextCellValue('Employé: ${user.firstName} ${user.lastName}')]);
      sheet.appendRow([TextCellValue('Entreprise: ${user.company}')]);

      final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(DateTime.now().year, monthNumber));
      sheet.appendRow([TextCellValue('Période: $monthName')]);

      // Ajuster la largeur des colonnes
      for (int i = 0; i < 8; i++) {
        sheet.setColumnWidth(i, 15);
      }

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final fileName = 'timesheet_${monthName.replaceAll(' ', '_')}.xlsx';
      final file = File('$path/$fileName');

      // S'assurer que le fichier est bien généré
      final excelBytes = excel.save(fileName: fileName);
      if (excelBytes != null && excelBytes.isNotEmpty) {
        await file.writeAsBytes(excelBytes);
      } else {
        throw Exception('Impossible de générer le fichier Excel: aucune donnée');
      }

      // Sauvegarder les métadonnées (réutiliser la table des PDF générés)
      final generatedFile = GeneratedPdf(
        fileName: fileName,
        filePath: file.path,
        generatedDate: DateTime.now(),
      );
      await repository.saveGeneratedPdf(generatedFile);

      return file;
    } catch (e) {
      throw Exception('Erreur lors de la génération du fichier Excel: $e');
    }
  }

  String _getDayName(int weekday) {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[weekday];
  }
}
