import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:time_sheet/features/time_sheet/domain/entities/work_day.dart';
import 'package:time_sheet/features/time_sheet/domain/repositories/timesheet_repository.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../services/logger_service.dart';
import '../../../../../preference/domain/use_cases/get_signature_usecase.dart';
import '../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../data/models/generated_pdf/generated_pdf.dart';
import '../../../../domain/entities/work_week.dart';
import '../../../../domain/use_cases/generate_week_usecase.dart';

part 'pdf_event.dart';

part 'pdf_state.dart';

class PdfBloc extends Bloc<PdfEvent, PdfState> {
  final TimesheetRepository repository;
  final GetSignatureUseCase getSignatureUseCase;

  PdfBloc(this.repository, this.getSignatureUseCase) : super(PdfInitial()) {
    on<GeneratePdfEvent>(_onGeneratePdfEvent);
    on<LoadGeneratedPdfsEvent>(_onLoadGeneratedPdfsEvent);
    on<DeletePdfEvent>(_onDeletePdfEvent);
    on<OpenPdfEvent>(_onOpenPdfEvent);
    on<SignPdfEvent>(_onSignPdfEvent);
    on<ClosePdfEvent>((event, emit) {
      emit(PdfClosed());
      add(LoadGeneratedPdfsEvent());
    });
  }

  Future<void> _onGeneratePdfEvent(
      GeneratePdfEvent event, Emitter<PdfState> emit) async {
    emit(PdfGenerating());
    try {
      final timesheetEntryList = await repository.findEntriesFromMonthOf(event.monthNumber);
      List<WorkWeek> weekDay =
          WeekGeneratorUseCase().execute(timesheetEntryList);
      final signature = await getSignatureUseCase.execute();
      final pdfFile = await generatePdf(weekDay, signature);

      // Sauvegarder les informations du PDF généré
      final generatedPdf = GeneratedPdfModel(
        fileName: pdfFile.path.split('/').last,
        filePath: pdfFile.path,
        generatedDate: DateTime.now(),
      );
      await repository.saveGeneratedPdf(generatedPdf);

      emit(PdfGenerated(pdfFile.path));
      add(LoadGeneratedPdfsEvent());
    } catch (e) {
      emit(PdfGenerationError(e.toString()));
    }
  }

  Future<void> _onLoadGeneratedPdfsEvent(
      LoadGeneratedPdfsEvent event, Emitter<PdfState> emit) async {
    emit(PdfLoading());
    try {
      final pdfList = await repository.getGeneratedPdfs();
      emit(PdfListLoaded(pdfList));
    } catch (e) {
      emit(PdfLoadError(e.toString()));
    }
  }

  Future<void> _onDeletePdfEvent(
      DeletePdfEvent event, Emitter<PdfState> emit) async {
    emit(PdfLoading());
    try {
      await repository.deleteGeneratedPdf(event.pdfId);
      add(LoadGeneratedPdfsEvent());
    } catch (e) {
      emit(PdfDeleteError(e.toString()));
    }
  }

  Future<void> _onOpenPdfEvent(
      OpenPdfEvent event, Emitter<PdfState> emit) async {
    emit(PdfOpening());
    try {
      emit(PdfOpened(event.filePath));
    } catch (e) {
      emit(PdfOpenError(e.toString()));
    }
  }

  Future<void> _onSignPdfEvent(
      SignPdfEvent event, Emitter<PdfState> emit) async {
    emit(PdfSigning());
    try {
      final String signedFilePath =
          await signPdf(event.filePath, event.signature);
      emit(PdfSigned(signedFilePath));
    } catch (e) {
      emit(PdfSignError(e.toString()));
    }
  }
}

Future<Uint8List> _loadImage() async {
  final byteData = await rootBundle.load('assets/images/logo-sonrysa.png');
  return byteData.buffer.asUint8List();
}

Future<File> generatePdf(List<WorkWeek> weeks, Uint8List? signature) async {
  logger.i('start generatedPdf');
  final pdf = pw.Document();

  // Chargez la police Helvetica
  final fontData = await rootBundle.load("assets/fonts/helvetica.ttf");
  final ttf = pw.Font.ttf(fontData.buffer.asByteData());

  // Chargez le logo
  final logoImage = pw.MemoryImage(await _loadImage());

  // Convertissez la signature en pw.Image si elle existe
  pw.Image? signatureImage;
  if (signature != null) {
    signatureImage = pw.Image(pw.MemoryImage(signature));
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.copyWith(
        marginBottom: 10,
        marginTop: 10,
        marginLeft: 10,
        marginRight: 10,
      ),
      build: (pw.Context context) => [
        _buildHeader(logoImage),
        _buildInfoTable(),
        ...weeks.map((week) => _buildWeekTable(week)),
        _buildFooter(signatureImage),
      ],
      theme: pw.ThemeData.withFont(
        base: ttf,
      ),
    ),
  );
  Directory directory = await getApplicationDocumentsDirectory();
  final path = directory.path;
  await Directory(path).create(recursive: true);
  final random = Random();
  final randomNumber =
      random.nextInt(100); // Génère un nombre aléatoire entre 0 et 99
  final file = File('$path/exemple$randomNumber.pdf');
  logger.i('end generatedPdf ${file.path}');
  return file.writeAsBytes(await pdf.save());
}

pw.Widget _buildInfoTable() {
  return pw.Table(
    border: pw.TableBorder.all(),
    children: [
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text('Entreprise de mission (Company): Avasad',
                style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text('Travailleur: Jonathan LEMAINE',
                style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      ),
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text('Mois: mai-2024',
                style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Container(),
        ],
      ),
    ],
  );
}

pw.Widget _buildHeader(pw.MemoryImage logoImage) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Note de temps',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        pw.Image(logoImage, width: 70),
      ],
    ),
  );
}

pw.Widget _buildWeekTable(WorkWeek week) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 10),
    child: pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.5),
        7: const pw.FlexColumnWidth(2),
      },
      children: [
        _buildTableHeader(),
        ...week.workday.map(_buildDayRow),
        _buildWeekTotal(week),
      ],
    ),
  );
}

pw.TableRow _buildTableHeader() {
  return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _centeredHeaderText('Date'),
        _centeredHeaderText('de'),
        _centeredHeaderText('à'),
        _centeredHeaderText('de'),
        _centeredHeaderText('à'),
        _centeredHeaderText('Total heures\ntravaillées'),
        _centeredHeaderText('Dont heures\nsupplémentaires'),
        _centeredHeaderText('Commentaires'),
      ]);
}

pw.TableRow _buildDayRow(Workday day) {
  String formattedDate = _formatDate(day.entry.dayDate);
  String dayOfWeek = _dayOfWeek(day.entry.dayDate);
  return pw.TableRow(
    children: [
      pw.Center(
        child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 5, right: 5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(dayOfWeek, style: const pw.TextStyle(fontSize: 6)),
                pw.Text(formattedDate, style: const pw.TextStyle(fontSize: 6)),
              ],
            )),
      ),
      pw.Center(
          child: pw.Text(day.entry.startMorning,
              style: const pw.TextStyle(fontSize: 6))),
      pw.Center(
          child: pw.Text(day.entry.endMorning,
              style: const pw.TextStyle(fontSize: 6))),
      pw.Center(
          child: pw.Text(day.entry.startAfternoon,
              style: const pw.TextStyle(fontSize: 6))),
      pw.Center(
          child: pw.Text(day.entry.endAfternoon,
              style: const pw.TextStyle(fontSize: 6))),
      pw.Center(
          child: pw.Text(day.formatDuration(day.calculateTotalHours()),
              style: const pw.TextStyle(fontSize: 6))),
      pw.Center(child: pw.Text('', style: const pw.TextStyle(fontSize: 6))),
      pw.Center(child: pw.Text('', style: const pw.TextStyle(fontSize: 6))),
      // Commentaires non implémentés
    ]
        .map((widget) =>
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: widget))
        .toList(),
  );
}

pw.TableRow _buildWeekTotal(WorkWeek week) {
  return pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
    children: [
      pw.Text('Total de la semaine:',
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
      pw.Text(''),
      pw.Text(''),
      pw.Text(''),
      pw.Text(''),
      pw.Center(
          child: pw.Text(week.formatDuration(week.calculateTotalWeekHours()),
              style:
                  pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
      pw.Text(''),
    ]
        .map((widget) =>
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: widget))
        .toList(),
  );
}

pw.Widget _buildFooter(pw.Image? signatureImage) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 15),
    child: pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _buildSignatureColumn('Travailleur', 'Jonathan LEMAINE', signatureImage),
                _buildSignatureColumn(
                    'Entreprise de mission', 'François Longchamp'),
                _buildSignatureColumn('Delivery manager', 'Sovattha Sok'),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date: ${DateFormat('dd.MM.yyyy').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8)),
            pw.Text(
                'Je certifie sur l\'honneur que j\'ai travaillé durant ces horaires et heures travaillées',
                style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildSignatureColumn(String title, String name,
    [pw.Image? signatureImage]) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        if (signatureImage != null)
          pw.Container(
            height: 25, // Ajustez la taille selon vos besoins
            width: 100, // Ajustez la taille selon vos besoins
            child: signatureImage,
          )
        else
          pw.SizedBox(height: 25), // Espace pour la signature
        pw.Container(
          width: 100,
          height: 1,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 5),
        pw.Text(name, style: const pw.TextStyle(fontSize: 8)),
      ],
    ),
  );
}

String _dayOfWeek(String dateString) {
  try {
    final date = DateFormat('dd-MMM-yy', 'en_US').parse(dateString);
    return DateFormat('EEEE', 'fr_FR').format(date);
  } catch (e) {
    print('Erreur lors du formatage de la date: $e');
    return dateString;
  }
}

String _formatDate(String dateString) {
  try {
    final date = DateFormat('dd-MMM-yy', 'en_US').parse(dateString);
    return DateFormat('dd-MMM-yy', 'fr_FR').format(date);
  } catch (e) {
    print('Erreur lors du formatage de la date: $e');
    return dateString;
  }
}

pw.Widget _centeredHeaderText(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(2),
    child: pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    ),
  );
}

Future<String> signPdf(String filePath, Uint8List signature) async {
  final file = File(filePath);
  final pdfBytes = await file.readAsBytes();
  final pdfDocument = pw.Document();

  final signatureImage = pw.MemoryImage(signature);

  pdfDocument.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Stack(
          children: [
            pw.Positioned(
              bottom: 50,
              right: 50,
              child: pw.Image(signatureImage, width: 100, height: 50),
            ),
          ],
        );
      },
    ),
  );

  final signedFilePath =
      '${file.parent.path}/signed_${DateTime.now().millisecondsSinceEpoch}.pdf';
  final signedFile = File(signedFilePath);
  await signedFile.writeAsBytes(await pdfDocument.save());

  return signedFilePath;
}
