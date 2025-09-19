import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:convert';
import '../generated/protocol.dart';
import 'weekend_overtime_calculator_service.dart';

class PdfGeneratorService {
  final WeekendOvertimeCalculatorService _overtimeCalculator =
      WeekendOvertimeCalculatorService();

  Future<Uint8List> generateTimesheetPdf({
    required TimesheetData timesheetData,
    required ValidationRequest validation,
    String? managerSignature,
    bool includeManagerSignature = false,
  }) async {
    print('\n========== PDF GENERATOR SERVICE ==========');
    print('Validation ID: ${validation.id}');
    print('Include manager signature param: $includeManagerSignature');
    print('Manager signature parameter provided: ${managerSignature != null}');
    if (managerSignature != null) {
      print('  - Length: ${managerSignature.length}');
    }
    print('Manager name: ${validation.managerName}');

    final pdf = pw.Document();

    // Décoder les entrées JSON
    final entriesJson = jsonDecode(timesheetData.entries) as List;
    final entries = entriesJson.map((e) => e as Map<String, dynamic>).toList();

    // Calculer les heures supplémentaires par type
    final overtimeSummary =
        _overtimeCalculator.calculateOvertimeSummary(timesheetData);

    // Créer le PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // En-tête
            _buildHeader(timesheetData, validation),
            pw.SizedBox(height: 20),

            // Informations de l'employé
            _buildEmployeeInfo(timesheetData),
            pw.SizedBox(height: 20),

            // Tableau des entrées avec indicateurs weekend
            _buildEntriesTable(entries),
            pw.SizedBox(height: 20),

            // Totaux avec séparation weekend/semaine
            _buildTotals(timesheetData, overtimeSummary),
            pw.SizedBox(height: 20),

            // Section heures supplémentaires détaillée
            _buildOvertimeBreakdown(overtimeSummary),
            pw.SizedBox(height: 40),

            // Signatures
            _buildSignatures(
                validation, includeManagerSignature, managerSignature),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
      TimesheetData timesheetData, ValidationRequest validation) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'FEUILLE DE TEMPS',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Période: ${timesheetData.month}/${timesheetData.year}'),
          pw.Text('Statut: ${_getStatusText(validation.status)}'),
          if (validation.validatedAt != null)
            pw.Text(
                'Date de validation: ${_formatDate(validation.validatedAt!)}'),
        ],
      ),
    );
  }

  pw.Widget _buildEmployeeInfo(TimesheetData timesheetData) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Informations de l\'employé',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text('Nom: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(timesheetData.employeeName),
            ],
          ),
          pw.Row(
            children: [
              pw.Text('ID: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(timesheetData.employeeId),
            ],
          ),
          pw.Row(
            children: [
              pw.Text('Entreprise: ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(timesheetData.employeeCompany),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEntriesTable(List<Map<String, dynamic>> entries) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      children: [
        // En-tête du tableau
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Type', isHeader: true),
            _buildTableCell('Matin\nDébut', isHeader: true),
            _buildTableCell('Matin\nFin', isHeader: true),
            _buildTableCell('Après-midi\nDébut', isHeader: true),
            _buildTableCell('Après-midi\nFin', isHeader: true),
            _buildTableCell('Total', isHeader: true),
            _buildTableCell('HS', isHeader: true),
          ],
        ),
        // Lignes de données
        ...entries.map((entry) {
          final isAbsence = entry['isAbsence'] ?? false;
          final hasOvertime = entry['hasOvertimeHours'] ?? false;
          final dayDate = entry['dayDate'] as String? ?? '';
          final isWeekend = _isWeekendDay(dayDate);

          // Calculer le total d'heures pour cette journée
          final totalMinutes = _calculateDailyMinutes(entry);
          final totalHours = _formatMinutesAsTime(totalMinutes);

          // Déterminer le type de jour
          String dayType = '';
          if (isAbsence) {
            dayType = 'Absence';
          } else if (isWeekend) {
            dayType = 'Weekend';
          } else {
            dayType = 'Semaine';
          }

          return pw.TableRow(
            decoration: isWeekend && !isAbsence
                ? const pw.BoxDecoration(color: PdfColors.blue50)
                : null,
            children: [
              _buildTableCell(dayDate),
              _buildTableCell(dayType, isWeekend: isWeekend && !isAbsence),
              _buildTableCell(
                  isAbsence ? 'Absence' : (entry['startMorning'] ?? '')),
              _buildTableCell(isAbsence ? '' : (entry['endMorning'] ?? '')),
              _buildTableCell(isAbsence ? '' : (entry['startAfternoon'] ?? '')),
              _buildTableCell(isAbsence ? '' : (entry['endAfternoon'] ?? '')),
              _buildTableCell(totalHours),
              _buildTableCell(
                  hasOvertime || (isWeekend && !isAbsence && totalMinutes > 0)
                      ? 'Oui'
                      : ''),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text,
      {bool isHeader = false, bool isWeekend = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
          color: isWeekend ? PdfColors.blue800 : PdfColors.black,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTotals(
      TimesheetData timesheetData, OvertimeSummaryData overtimeSummary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Totaux',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Jours travaillés:'),
              pw.Text('${timesheetData.totalDays.toStringAsFixed(1)} jours'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Heures totales:'),
              pw.Text(timesheetData.totalHours),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Heures régulières:'),
              pw.Text(overtimeSummary.formattedRegularHours),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Heures supplémentaires totales:'),
              pw.Text(overtimeSummary.formattedTotalOvertime),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatures(ValidationRequest validation,
      bool includeManagerSignature, String? managerSignature) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Signatures',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Signature de l'employé
              pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Employé:'),
                    pw.Container(
                      height: 60,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black),
                        ),
                      ),
                      child: pw.Center(
                        child: pw.Text('Signature électronique'),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Date: ${_formatDate(validation.createdAt ?? DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Signature du manager
              pw.Container(
                width: 200,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Manager:'),
                    pw.Container(
                      height: 60,
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.black),
                        ),
                      ),
                      child: pw.Center(
                        child: (includeManagerSignature &&
                                managerSignature != null &&
                                managerSignature.isNotEmpty)
                            ? _buildSignatureImage(managerSignature, validation)
                            : pw.Text(''),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (validation.managerName != null)
                      pw.Text(validation.managerName!,
                          style: const pw.TextStyle(fontSize: 10)),
                    if (validation.validatedAt != null)
                      pw.Text(
                        'Date: ${_formatDate(validation.validatedAt!)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (validation.managerComment != null &&
              validation.managerComment!.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Commentaire du manager:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(validation.managerComment!),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildSignatureImage(
      String signatureBase64, ValidationRequest validation) {
    try {
      print('\n========== BUILDING SIGNATURE IMAGE ==========');
      print('Input signature length: ${signatureBase64.length}');
      print(
          'First 100 chars: ${signatureBase64.substring(0, signatureBase64.length > 100 ? 100 : signatureBase64.length)}');

      // La signature est DÉJÀ en base64 dans la DB, on la décode directement
      String cleanBase64 = signatureBase64;

      // Si c'est un data URI (data:image/png;base64,...), on extrait juste la partie base64
      if (signatureBase64.startsWith('data:')) {
        print('Signature has data URI prefix, removing it');
        cleanBase64 = signatureBase64.split(',').last;
      }

      print('Clean base64 length: ${cleanBase64.length}');

      // Décoder la signature base64 en bytes
      final signatureBytes = base64Decode(cleanBase64);
      print('Decoded to ${signatureBytes.length} bytes');

      // Créer l'image pour le PDF
      final image = pw.Image(
        pw.MemoryImage(signatureBytes),
        width: 150,
        height: 50,
        fit: pw.BoxFit.contain,
      );

      print('SUCCESS: Signature image created');
      return image;
    } catch (e, stack) {
      print('\n========== ERROR BUILDING SIGNATURE ==========');
      print('Error: $e');
      print('Stack trace: $stack');
      print('Falling back to text signature');
      return pw.Text(
        validation.managerName ?? 'Signature électronique',
        style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getStatusText(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
        return 'En attente';
      case ValidationStatus.approved:
        return 'Approuvée';
      case ValidationStatus.rejected:
        return 'Rejetée';
      case ValidationStatus.expired:
        return 'Expirée';
    }
  }

  /// Builds the detailed overtime breakdown section
  pw.Widget _buildOvertimeBreakdown(OvertimeSummaryData overtimeSummary) {
    if (!overtimeSummary.hasOvertime) {
      return pw.Container(); // Don't show section if no overtime
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Détail des Heures Supplémentaires',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),

          // Heures supplémentaires semaine
          if (overtimeSummary.hasWeekdayOvertime) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                color: PdfColors.white,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Heures supplémentaires - Semaine',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Heures travaillées:'),
                      pw.Text(overtimeSummary.formattedWeekdayOvertime),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Taux de majoration:'),
                      pw.Text(
                          '${(overtimeSummary.weekdayOvertimeRate * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],

          // Heures supplémentaires weekend
          if (overtimeSummary.hasWeekendOvertime) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                color: PdfColors.white,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Heures supplémentaires - Weekend',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Heures travaillées:'),
                      pw.Text(overtimeSummary.formattedWeekendOvertime),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Taux de majoration:'),
                      pw.Text(
                          '${(overtimeSummary.weekendOvertimeRate * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Note: Toutes les heures travaillées le weekend sont considérées comme heures supplémentaires.',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Determines if a given date string represents a weekend day
  bool _isWeekendDay(String dayDate) {
    try {
      // Parse date string (assuming format like "2025-01-18" or similar)
      final date = DateTime.parse(dayDate);
      return date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday;
    } catch (e) {
      // If parsing fails, assume it's not a weekend
      return false;
    }
  }

  /// Calculates total minutes worked in a day from entry data
  int _calculateDailyMinutes(Map<String, dynamic> entry) {
    try {
      int totalMinutes = 0;

      // Morning session
      final startMorning = entry['startMorning'] as String?;
      final endMorning = entry['endMorning'] as String?;
      if (startMorning != null &&
          endMorning != null &&
          startMorning.isNotEmpty &&
          endMorning.isNotEmpty) {
        totalMinutes += _calculateSessionMinutes(startMorning, endMorning);
      }

      // Afternoon session
      final startAfternoon = entry['startAfternoon'] as String?;
      final endAfternoon = entry['endAfternoon'] as String?;
      if (startAfternoon != null &&
          endAfternoon != null &&
          startAfternoon.isNotEmpty &&
          endAfternoon.isNotEmpty) {
        totalMinutes += _calculateSessionMinutes(startAfternoon, endAfternoon);
      }

      return totalMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Calculates minutes between two time strings
  int _calculateSessionMinutes(String startTime, String endTime) {
    try {
      final start = _parseTimeString(startTime);
      final end = _parseTimeString(endTime);

      if (start == null || end == null) return 0;

      final difference = end.difference(start);
      return difference.inMinutes;
    } catch (e) {
      return 0;
    }
  }

  /// Parses a time string (e.g., "09:00") into a DateTime
  DateTime? _parseTimeString(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      // Use a fixed date, we only care about time
      return DateTime(2025, 1, 1, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Formats minutes as time string (e.g., "8:30")
  String _formatMinutesAsTime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}:${remainingMinutes.toString().padLeft(2, '0')}';
  }
}
