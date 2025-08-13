import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_usecase.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/generate_pdf_params.dart';

part 'pdf_event_simple.dart';
part 'pdf_state_simple.dart';

/// Version simplifiée du PdfBloc pour la génération de validation
class PdfBlocSimple extends Bloc<PdfEventSimple, PdfStateSimple> {
  final GeneratePdfUseCase generatePdfUseCase;

  PdfBlocSimple({required this.generatePdfUseCase}) : super(PdfInitialSimple()) {
    on<GeneratePdfEventSimple>(_onGeneratePdfEvent);
  }

  Future<void> _onGeneratePdfEvent(
    GeneratePdfEventSimple event,
    Emitter<PdfStateSimple> emit,
  ) async {
    emit(PdfGeneratingSimple());
    
    try {
      final result = await generatePdfUseCase.call(event.params);
      
      result.fold(
        (failure) => emit(PdfGenerationErrorSimple((failure as dynamic).message ?? 'Erreur inconnue')),
        (pdfBytes) => emit(PdfGeneratedSimple(pdfBytes)),
      );
    } catch (e) {
      emit(PdfGenerationErrorSimple('Erreur inattendue: $e'));
    }
  }
}