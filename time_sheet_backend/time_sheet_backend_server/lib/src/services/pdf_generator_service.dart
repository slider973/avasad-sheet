import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io';
import '../generated/protocol.dart';

class PdfGeneratorService {
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

            // Tableau des entrées
            _buildEntriesTable(entries),
            pw.SizedBox(height: 20),

            // Totaux
            _buildTotals(timesheetData),
            pw.SizedBox(height: 40),

            // Signatures
            _buildSignatures(validation, includeManagerSignature, managerSignature),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(TimesheetData timesheetData, ValidationRequest validation) {
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
          if (validation.validatedAt != null) pw.Text('Date de validation: ${_formatDate(validation.validatedAt!)}'),
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
              pw.Text('Nom: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(timesheetData.employeeName),
            ],
          ),
          pw.Row(
            children: [
              pw.Text('ID: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(timesheetData.employeeId),
            ],
          ),
          pw.Row(
            children: [
              pw.Text('Entreprise: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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

          // Calculer le total d'heures pour cette journée
          String totalHours = '0:00';
          if (!isAbsence && entry['startMorning'] != null && entry['endMorning'] != null) {
            // Calculer les heures (simplification)
            totalHours = '8:00'; // À améliorer avec un vrai calcul
          }

          return pw.TableRow(
            children: [
              _buildTableCell(entry['dayDate'] ?? ''),
              _buildTableCell(isAbsence ? 'Absence' : (entry['startMorning'] ?? '')),
              _buildTableCell(isAbsence ? '' : (entry['endMorning'] ?? '')),
              _buildTableCell(isAbsence ? '' : (entry['startAfternoon'] ?? '')),
              _buildTableCell(isAbsence ? '' : (entry['endAfternoon'] ?? '')),
              _buildTableCell(totalHours),
              _buildTableCell(hasOvertime ? 'Oui' : ''),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 10 : 9,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTotals(TimesheetData timesheetData) {
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
              pw.Text('Heures supplémentaires:'),
              pw.Text(timesheetData.totalOvertimeHours),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatures(ValidationRequest validation, bool includeManagerSignature, String? managerSignature) {
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
                        child: (includeManagerSignature && managerSignature != null && managerSignature.isNotEmpty)
                            ? _buildSignatureImage(managerSignature, validation)
                            : pw.Text(''),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    if (validation.managerName != null)
                      pw.Text(validation.managerName!, style: const pw.TextStyle(fontSize: 10)),
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
          if (validation.managerComment != null && validation.managerComment!.isNotEmpty) ...[
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

  pw.Widget _buildSignatureImage(String signatureBase64, ValidationRequest validation) {
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
      default:
        return 'Inconnu';
    }
  }
}
