import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/error/failures.dart';
import '../entities/expense.dart';
import '../entities/expense_report.dart';
import '../repositories/expense_repository.dart';
import '../../../preference/domain/use_cases/get_signature_usecase.dart';
import '../../../preference/domain/use_cases/get_user_preference_use_case.dart';

/// Use case pour générer un PDF de note de frais
class GenerateExpensePdfUseCase {
  final ExpenseRepository repository;
  final GetSignatureUseCase getSignatureUseCase;
  final GetUserPreferenceUseCase getUserPreferenceUseCase;

  GenerateExpensePdfUseCase({
    required this.repository,
    required this.getSignatureUseCase,
    required this.getUserPreferenceUseCase,
  });

  Future<Either<Failure, String>> execute({
    required int month,
    required int year,
  }) async {
    try {
      // 1. Récupérer le rapport mensuel
      final reportResult = await repository.getMonthlyReport(month, year);

      if (reportResult.isLeft()) {
        return Left(reportResult.fold((l) => l, (r) => throw Exception()));
      }

      final report = reportResult.getRight().getOrElse(() => throw Exception());

      if (report.expenses.isEmpty) {
        return const Left(ValidationFailure('Aucune dépense ce mois-ci'));
      }

      // 2. Récupérer les infos utilisateur
      final firstName = await getUserPreferenceUseCase.execute('firstName') ?? '';
      final lastName = await getUserPreferenceUseCase.execute('lastName') ?? '';
      final company = await getUserPreferenceUseCase.execute('company') ?? 'Avasad';
      final signature = await getSignatureUseCase.execute();

      // 3. Générer le PDF
      final pdfFile = await _generatePdf(
        report: report,
        month: month,
        year: year,
        employeeName: '$firstName $lastName',
        company: company,
        signature: signature,
      );

      return Right(pdfFile.path);
    } catch (e) {
      return Left(GeneralFailure('Erreur lors de la génération du PDF: $e'));
    }
  }

  Future<File> _generatePdf({
    required ExpenseReport report,
    required int month,
    required int year,
    required String employeeName,
    required String company,
    Uint8List? signature,
  }) async {
    final pdf = pw.Document();

    // Charger la police
    final fontData = await rootBundle.load("assets/fonts/helvetica.ttf");
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());

    // Charger le logo
    final logoData = await rootBundle.load('assets/images/logo-sonrysa.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Signature
    pw.Image? signatureImage;
    if (signature != null) {
      signatureImage = pw.Image(pw.MemoryImage(signature));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(logoImage, employeeName, month, year),
              pw.SizedBox(height: 20),

              // Tableau des dépenses
              _buildExpenseTable(report.expenses),
              pw.SizedBox(height: 10),

              // Total
              _buildTotal(report.totalAmount),
              pw.Spacer(),

              // Signatures
              _buildSignatures(employeeName, signatureImage),
              pw.SizedBox(height: 10),

              // Accord pour remboursement
              _buildAgreement(),
            ],
          );
        },
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
      ),
    );

    // Sauvegarder le fichier
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/expense_reports/$company';
    await Directory(path).create(recursive: true);

    final monthName = DateFormat('MMM', 'fr_FR').format(DateTime(year, month));
    final fileName = 'Note_de_frais_${monthName}_$year.pdf';
    final file = File('$path/$fileName');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildHeader(
    pw.MemoryImage logo,
    String employeeName,
    int month,
    int year,
  ) {
    final monthName = DateFormat('MMM', 'fr_FR')
        .format(DateTime(year, month))
        .toLowerCase()
        .replaceAll('.', '');

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logo, width: 100),
              pw.Container(
                width: 1,
                height: 50,
                color: PdfColors.black,
              ),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Claimant',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(employeeName, style: const pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Month',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '$monthName.$year',
                        style: const pw.TextStyle(fontSize: 16, color: PdfColors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildExpenseTable(List<Expense> expenses) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),   // Ref No
        1: const pw.FixedColumnWidth(50),   // Date
        2: const pw.FlexColumnWidth(3),     // Description
        3: const pw.FixedColumnWidth(40),   // Currency
        4: const pw.FixedColumnWidth(45),   // xch. rate
        5: const pw.FixedColumnWidth(35),   // Km
        6: const pw.FixedColumnWidth(70),   // Total
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Ref No', isHeader: true),
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Currency', isHeader: true),
            _buildTableCell('xch. rate', isHeader: true),
            _buildTableCell('Km', isHeader: true),
            _buildTableCell('Total (in CHF)', isHeader: true),
          ],
        ),
        // Rows
        ...expenses.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final expense = entry.value;

          return pw.TableRow(
            children: [
              _buildTableCell('$index'),
              _buildTableCell(DateFormat('dd.MMM').format(expense.date)),
              _buildTableCell(expense.description),
              _buildTableCell(expense.currency),
              _buildTableCell(
                expense.mileageRate?.toStringAsFixed(2) ?? '',
              ),
              _buildTableCell(expense.distanceKm?.toString() ?? ''),
              _buildTableCell(
                expense.calculatedAmount.toStringAsFixed(2),
                isTotal: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader || isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isTotal ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildTotal(double totalAmount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Total (in CHF)',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(width: 20),
          pw.Text(
            '${totalAmount.toStringAsFixed(2)} CHF',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatures(String employeeName, pw.Image? signature) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Signed Claimant',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'N.B. @Sonrysa : bien préciser qu\'il s\'agit des frais liés au pilote d\'Avenches lors de la refacturation à l\'AVASAD',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 10),
          if (signature != null)
            pw.Container(
              height: 40,
              child: signature,
            )
          else
            pw.SizedBox(height: 40),
          pw.SizedBox(height: 10),
          pw.Text(
            'Signed by client or director',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAgreement() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Accord pour remboursement',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }
}
