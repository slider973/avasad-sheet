import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:time_sheet/features/pointage/domain/entities/generated_pdf.dart';
import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_params.dart';

part 'pdf_event_simple.dart';
part 'pdf_state_simple.dart';

/// Version simplifiée du PdfBloc pour la génération de validation
class PdfBlocSimple extends Bloc<PdfEventSimple, PdfStateSimple> {
  final GeneratePdfUseCase generatePdfUseCase;
  final TimesheetRepository? repository;
  final String? company;

  PdfBlocSimple({
    required this.generatePdfUseCase,
    this.repository,
    this.company,
  }) : super(PdfInitialSimple()) {
    on<GeneratePdfEventSimple>(_onGeneratePdfEvent);
  }

  Future<void> _onGeneratePdfEvent(
    GeneratePdfEventSimple event,
    Emitter<PdfStateSimple> emit,
  ) async {
    emit(PdfGeneratingSimple());

    try {
      final result = await generatePdfUseCase.call(event.params);

      await result.fold(
        (failure) async => emit(PdfGenerationErrorSimple((failure as dynamic).message ?? 'Erreur inconnue')),
        (pdfBytes) async {
          // Sauvegarder le fichier sur disque et dans la DB
          if (repository != null) {
            try {
              final output = await getApplicationDocumentsDirectory();
              final monthName = DateFormat('MMMM', 'fr_FR').format(
                DateTime(event.params.year, event.params.monthNumber),
              );
              final year = event.params.year;
              final fileName = '${monthName}_$year.pdf';

              final path = '${output.path}/extract-time-sheet/${company ?? 'Default'}';
              await Directory(path).create(recursive: true);

              final file = File('$path/$fileName');
              await file.writeAsBytes(pdfBytes);

              await repository!.saveGeneratedPdf(GeneratedPdf(
                fileName: fileName,
                filePath: file.path,
                generatedDate: DateTime.now(),
              ));
            } catch (_) {
              // La sauvegarde a échoué mais le PDF est quand même généré
            }
          }

          emit(PdfGeneratedSimple(pdfBytes));
        },
      );
    } catch (e) {
      emit(PdfGenerationErrorSimple('Erreur inattendue: $e'));
    }
  }
}
