import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_day.dart';
import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';

import '../../../../../../../enum/absence_period.dart';
import '../../../../../../../services/logger_service.dart';
import '../../../../../../preference/domain/entities/user.dart';
import '../../../../../../preference/domain/use_cases/get_signature_usecase.dart';
import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../domain/entities/generated_pdf.dart';
import '../../../../../domain/entities/work_week.dart';
import '../../../../../domain/use_cases/generate_pdf_usecase.dart';
import '../../../../../domain/use_cases/generate_excel_usecase.dart';

part 'pdf_event.dart';

part 'pdf_state.dart';

final headerColor = PdfColor.fromHex('#D9D9D9'); // Gris clair pour l'en-tête
final totalRowColor =
    PdfColor.fromHex('#F2F2F2'); // Gris très clair pour les totaux

class PdfBloc extends Bloc<PdfEvent, PdfState> {
  final TimesheetRepository repository;
  final GetSignatureUseCase getSignatureUseCase;
  final PreferencesBloc preferencesBloc;
  final GeneratePdfUseCase generatePdfUseCase;
  final GenerateExcelUseCase generateExcelUseCase;

  PdfBloc(this.repository, this.getSignatureUseCase, this.preferencesBloc,
      this.generatePdfUseCase, this.generateExcelUseCase)
      : super(PdfInitial()) {
    on<GeneratePdfEvent>(_onGeneratePdfEvent);
    on<LoadGeneratedPdfsEvent>(_onLoadGeneratedPdfsEvent);
    on<DeletePdfEvent>(_onDeletePdfEvent);
    on<OpenPdfEvent>(_onOpenPdfEvent);
    on<SignPdfEvent>(_onSignPdfEvent);
    on<GenerateExcelEvent>(_onGenerateExcelEvent);
    on<ClosePdfEvent>((event, emit) {
      emit(PdfClosed());
      emit(PdfInitial());
      add(LoadGeneratedPdfsEvent());
    });
  }

  Future<void> _onGeneratePdfEvent(
      GeneratePdfEvent event, Emitter<PdfState> emit) async {
    emit(PdfGenerating());
    try {
      final result =
          await generatePdfUseCase.execute(event.monthNumber, event.year);

      result.match(
        (error) {
          String errorMessage =
              "Une erreur s'est produite lors de la génération du PDF: $error";
          emit(PdfGenerationError(errorMessage));
        },
        (pdfPath) {
          emit(PdfGenerated(pdfPath));
          add(LoadGeneratedPdfsEvent());
        },
      );
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
      String errorMessage =
          "Une erreur inattendue s'est produite lors de la génération du PDF.";
      emit(PdfGenerationError(errorMessage));
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

  Future<void> _onGenerateExcelEvent(
      GenerateExcelEvent event, Emitter<PdfState> emit) async {
    emit(PdfGenerating());
    try {
      final userState = preferencesBloc.state;
      if (userState is PreferencesLoaded) {
        final user = User(
          firstName: userState.firstName,
          lastName: userState.lastName,
          company: userState.company,
          signature: userState.signature,
          isDeliveryManager: userState.isDeliveryManager,
        );
        final file = await generateExcelUseCase.execute(event.monthNumber, user);
        emit(PdfGenerated(file.path));
        add(LoadGeneratedPdfsEvent());
      } else {
        emit(const PdfGenerationError('Utilisateur non trouvé'));
      }
    } catch (e) {
      emit(PdfGenerationError(e.toString()));
    }
  }
}

Future<Uint8List> _loadImage() async {
  final byteData = await rootBundle.load('assets/images/logo-sonrysa.png');
  return byteData.buffer.asUint8List();
}

Future<File> generatePdf(
    List<WorkWeek> weeks, int monthNumber, User user) async {
  logger.i('start generatedPdf');
  final pdf = pw.Document();

  // Chargez la police Helvetica
  final fontData = await rootBundle.load("assets/fonts/helvetica.ttf");
  final ttf = pw.Font.ttf(fontData.buffer.asByteData());

  // Chargez le logo
  final logoImage = pw.MemoryImage(await _loadImage());

  // Convertissez la signature en pw.Image si elle existe
  pw.Image? signatureImage;
  if (user.signature != null) {
    signatureImage = pw.Image(pw.MemoryImage(user.signature!));
  }

  double totalDays = weeks.fold(
      0.0,
      (sum, week) =>
          sum +
          week.workday.fold(0.0, (daySum, day) {
            if (day.entry.period == AbsencePeriod.halfDay.value) {
              return daySum + 0.5;
            } else if (!day.isAbsence()) {
              return daySum + 1;
            }
            return daySum;
          }));
  final totalHours = weeks.fold(
      Duration.zero, (sum, week) => sum + week.calculateTotalWeekHours());

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
        _buildInfoTable(monthNumber, user),
        ...weeks.map((week) => _buildWeekTable(week)),
        _buildMonthTotal(totalHours, totalDays),
        _buildFooter(signatureImage, user),
      ],
      theme: pw.ThemeData.withFont(
        base: ttf,
      ),
    ),
  );
  Directory directory = await getApplicationDocumentsDirectory();
  final path = '${directory.path}/extract-time-sheet/${user.company}';
  await Directory(path).create(recursive: true);
  // Obtenir le nom du mois en français
  final monthName = DateFormat('MMMM', 'fr_FR')
      .format(DateTime(DateTime.now().year, monthNumber));
  // Créer le nom du fichier avec le mois et l'année
  final fileName = '${monthName}_${DateTime.now().year}.pdf';
  final file = File('$path/$fileName');
  logger.i('end generatedPdf ${file.path}');
  return file.writeAsBytes(await pdf.save());
}

pw.Widget _buildInfoTable(int monthNumber, User user) {
  final monthName = DateFormat('MMMM', 'fr_FR')
      .format(DateTime(DateTime.now().year, monthNumber));
  final year = DateTime.now().year;

  return pw.Table(
    border: pw.TableBorder.all(),
    children: [
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text('Entreprise de mission (Company): ${user.company}',
                style: const pw.TextStyle(fontSize: 8)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text('Travailleur: ${user.fullName}',
                style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      ),
      pw.TableRow(
        children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text('Mois: $monthName-$year',
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
      color: headerColor,
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
        7: const pw.FlexColumnWidth(2.5),
      },
      children: [
        _buildTableHeader(),
        ...week.workday
            .map((day) => _buildDayRow(day, _isWeekday(day.entry.dayDate))),
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
        _centeredHeaderText('Jour\ntravaillé'),
      ]);
}

pw.TableRow _buildDayRow(Workday day, bool isWeekday) {
  bool isHalfDayAbsence = day.entry.period == AbsencePeriod.halfDay.value;
  bool isFullDayAbsence = day.isAbsence() && !isHalfDayAbsence;
  Duration workDuration = day.calculateTotalHours();
  String formattedDuration =
      isFullDayAbsence ? '0h00' : _formatDuration(workDuration);

  String daysWorked = isFullDayAbsence ? '0' : (isHalfDayAbsence ? '0.5' : '1');
  return pw.TableRow(
    children: [
      pw.Center(
        child: pw.Padding(
            padding: const pw.EdgeInsets.only(left: 5, right: 5),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(_dayOfWeek(day.entry.dayDate),
                    style: const pw.TextStyle(fontSize: 6)),
                pw.Text(_formatDate(day.entry.dayDate),
                    style: const pw.TextStyle(fontSize: 6)),
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
          child: pw.Text(formattedDuration,
              style: const pw.TextStyle(fontSize: 6))),
      pw.Center(child: pw.Text('', style: const pw.TextStyle(fontSize: 6))),
      pw.Center(
          child: pw.Text(day.entry.absenceReason ?? '',
              style: const pw.TextStyle(fontSize: 6))),
      pw.Center(
          child: pw.Text(daysWorked, style: const pw.TextStyle(fontSize: 6))),
    ]
        .map((widget) =>
            pw.Padding(padding: const pw.EdgeInsets.all(3), child: widget))
        .toList(),
  );
}

pw.TableRow _buildWeekTotal(WorkWeek week) {
  double daysWorked = week.workday.fold(0.0, (sum, day) {
    if (day.entry.period == AbsencePeriod.halfDay.value) {
      return sum + 0.5;
    } else if (!day.isAbsence()) {
      return sum + 1;
    }
    return sum;
  });
  String formattedDaysWorked = daysWorked.truncateToDouble() == daysWorked
      ? daysWorked.toStringAsFixed(0)
      : daysWorked.toStringAsFixed(1);
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
      pw.Text(''),
      pw.Center(
          child: pw.Text(
              '$formattedDaysWorked jour${daysWorked > 1 ? 's' : ''}',
              style:
                  pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold))),
    ]
        .map((widget) =>
            pw.Padding(padding: const pw.EdgeInsets.all(5), child: widget))
        .toList(),
  );
}

pw.Widget _buildMonthTotal(Duration totalHours, double totalDays) {
  String formattedTotalDays = totalDays.truncateToDouble() == totalDays
      ? totalDays.toStringAsFixed(0)
      : totalDays.toStringAsFixed(1);
  return pw.Container(
    color: totalRowColor,
    margin: const pw.EdgeInsets.only(top: 10),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Total du mois: ${_formatDuration(totalHours)}',
                style:
                    pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Jours travaillés:',
                style:
                    pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            pw.Text(formattedTotalDays,
                style:
                    pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildFooter(pw.Image? signatureImage, User user) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 15),
    child: pw.Column(
      children: [
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              children: [
                _buildSignatureColumn(
                    'Travailleur', user.fullName, signatureImage),
                _buildSignatureColumn(
                    'Entreprise de mission', 'François Longchamp'),
                _buildSignatureColumn('Delivery manager', 'Sovattha Sok',
                    user.isDeliveryManager ? signatureImage : null),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
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
            height: 30, // Ajustez la taille selon vos besoins
            width: 300, // Ajustez la taille selon vos besoins
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
    return DateFormat('dd-MMM-yy', 'fr_FR').format(date).toLowerCase();
  } catch (e) {
    print('Erreur lors du formatage de la date: $e');
    return dateString;
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  return '${hours}h ${minutes}min';
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

bool _isWeekday(String dateString) {
  final date = DateFormat('dd-MMM-yy', 'en_US').parse(dateString);
  return date.weekday >= 1 && date.weekday <= 5; // Du lundi (1) au vendredi (5)
}

Future<String> signPdf(String filePath, Uint8List signature) async {
  final file = File(filePath);
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
