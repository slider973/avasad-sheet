import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:time_sheet/pdf/domain/repositories/timesheet_repository.dart';

import '../../../../../services/logger_service.dart';
import '../../../../domain/entities/work_week.dart';
import '../../../../domain/use_cases/generate_week_usecase.dart';

part 'pdf_event.dart';
part 'pdf_state.dart';

class PdfBloc extends Bloc<PdfEvent, PdfState> {
  final TimesheetRepository repository;

  PdfBloc(this.repository) : super(PdfInitial()) {
    on<PdfEvent>((event, emit) {
      // TODO: implement event handler
    });
    on<GeneratePdfEvent>((event, emit) async {
      final timesheetEntryList = await repository.findEntriesFromMonthOf(1);
      List<WorkWeek> weekDay = WeekGeneratorUseCase().execute(timesheetEntryList);
      print(weekDay);
      await generatePdf(weekDay);
    });
  }
}

Future<Uint8List> _loadImage() async {
  final byteData = await rootBundle.load('assets/images/logo-heytalent.png');
  return byteData.buffer.asUint8List();
}

Future<void> generatePdf(List<WorkWeek> weeks) async {
  logger.i('start generatedPdf');
  final fontData = await rootBundle.load("assets/fonts/helvetica.ttf");
  final ttf = pw.Font.ttf(fontData.buffer.asByteData());
  final tealPdfColor = PdfColor.fromInt(Colors.teal.value);
  const textSize = 7.0;

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
            border: pw.Border.all(width: 1),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Image(pw.MemoryImage(imageBytes), width: 80, height: 80),
                pw.SizedBox(width: 10),
                pw.Text("Note de temps", style: const pw.TextStyle(fontSize: textSize)),
              ],
            ),
          ),
        ),
        pw.Table(
          border: pw.TableBorder.all(),
          tableWidth: pw.TableWidth.max,
          columnWidths: const {
            0: pw.FlexColumnWidth(1.5),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(7),
          },
          children: [
            pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('Entreprise de mission (Company):', style: const pw.TextStyle(fontSize: 7.0))),
                pw.Row(children: [pw.SizedBox(width: 2), pw.Text('Avasad', style: const pw.TextStyle(fontSize: 9.0))]),
                pw.Text('Travailleur:', style: const pw.TextStyle(fontSize: 9.0)),
                pw.Text('Jonathan LEMAINE', style: const pw.TextStyle(fontSize: 9.0)),
              ],
            ),
          ],
        ),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: const {
            0: pw.FlexColumnWidth(1.5),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(7),
          },
          children: [
            pw.TableRow(
              verticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.Text(''),
                pw.Text(' '),
                pw.Text('Mois:', style: const pw.TextStyle(fontSize: 9.0)),
                pw.Padding(padding: pw.EdgeInsets.all(5), child: pw.Text('février-2023', style: const pw.TextStyle(fontSize: 9.0))),
              ],
            ),
          ],
        ),
        for (var week in weeks) ...[
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
              4: pw.FlexColumnWidth(2),
              5: pw.FlexColumnWidth(2),
              6: pw.FlexColumnWidth(2),
              7: pw.FlexColumnWidth(2),
              8: pw.FlexColumnWidth(2),
            },
            children: [
              for (var day in week.workday)
                pw.TableRow(
                  verticalAlignment: pw.TableCellVerticalAlignment.middle,
                  children: [
                    pw.Text(day.entry.dayOfWeekDate, style: const pw.TextStyle(fontSize: textSize)),
                    pw.Center(child: pw.Text(day.entry.dayDate, style: const pw.TextStyle(fontSize: textSize))),
                    pw.Center(child: pw.Text(day.entry.startMorning, style: const pw.TextStyle(fontSize: textSize))),
                    pw.Center(child: pw.Text(day.entry.endMorning, style: const pw.TextStyle(fontSize: textSize))),
                    pw.Center(child: pw.Text(day.entry.startAfternoon, style: const pw.TextStyle(fontSize: textSize))),
                    pw.Center(child: pw.Text(day.entry.endAfternoon, style: const pw.TextStyle(fontSize: textSize))),
                    pw.Center(
                        child: pw.Padding(
                            padding: pw.EdgeInsets.all(3),
                            child: pw.Text(day.formatDuration(day.calculateTotalHours()),
                                style: const pw.TextStyle(
                                  fontSize: textSize,
                                )))),
                    pw.Text(''), // Heures supplémentaires
                    pw.Text(''), // Commentaires
                  ],
                ),
              //   pw.TableRow(
              //     children: [
              //       pw.Text('Total de la semaine:'),
              //       pw.Text(''),
              //       pw.Text(week.calculateTotalWeekHours().toString()), // Total heures
              //     ],
              //   ),
              pw.TableRow(
                children: [
                  // ... vos autres cellules ici ...
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Table(
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Text('Total de la semaine: ${week.formatDuration(week.calculateTotalWeekHours())}', style: const pw.TextStyle(fontSize: textSize)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ), // Espace entre chaque semaine
        ],
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
