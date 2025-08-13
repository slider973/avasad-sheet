import 'dart:async';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';
import 'package:intl/intl.dart';

import '../../../../../../preference/domain/entities/user.dart';
import '../../../../../../preference/domain/use_cases/get_signature_usecase.dart';
import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../domain/entities/generated_pdf.dart';
import '../../../../../domain/use_cases/generate_pdf_usecase.dart';
import '../../../../../domain/use_cases/generate_pdf_params.dart';
import '../../../../../domain/use_cases/generate_excel_usecase.dart';

part 'pdf_event.dart';

part 'pdf_state.dart';

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
      // Utiliser GeneratePdfUseCase avec les paramètres appropriés
      final params = GeneratePdfParams(
        monthNumber: event.monthNumber,
        year: event.year,
        // Ne pas inclure la signature du manager ici - l'employé génère le PDF
        managerSignature: null,
        managerName: null,
      );
      
      final result = await generatePdfUseCase.call(params);

      await result.fold(
        (failure) async {
          String errorMessage =
              "Une erreur s'est produite lors de la génération du PDF: ${failure.message}";
          if (!emit.isDone) {
            emit(PdfGenerationError(errorMessage));
          }
        },
        (pdfBytes) async {
          try {
            // Sauvegarder le PDF bytes dans un fichier avec le bon nom
            final output = await getApplicationDocumentsDirectory();
            final monthName = DateFormat('MMMM', 'fr_FR').format(DateTime(event.year, event.monthNumber));
            final fileName = '${monthName}_${event.year}.pdf';
            
            // Créer le répertoire si nécessaire
            final userState = preferencesBloc.state;
            String company = 'Avasad';
            if (userState is PreferencesLoaded) {
              company = userState.company;
            }
            
            final path = '${output.path}/extract-time-sheet/$company';
            await Directory(path).create(recursive: true);
            
            final file = File('$path/$fileName');
            await file.writeAsBytes(pdfBytes);
            
            // Sauvegarder les métadonnées dans le repository
            final generatedPdf = GeneratedPdf(
              fileName: fileName,
              filePath: file.path,
              generatedDate: DateTime.now(),
            );
            await repository.saveGeneratedPdf(generatedPdf);
            
            if (!emit.isDone) {
              emit(PdfGenerated(file.path));
              add(LoadGeneratedPdfsEvent());
            }
          } catch (e) {
            if (!emit.isDone) {
              emit(PdfGenerationError('Erreur lors de la sauvegarde du PDF: $e'));
            }
          }
        },
      );
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );
      String errorMessage =
          "Une erreur inattendue s'est produite lors de la génération du PDF.";
      if (!emit.isDone) {
        emit(PdfGenerationError(errorMessage));
      }
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
  
  Future<String> signPdf(String filePath, Uint8List signature) async {
    // Cette méthode est utilisée pour signer un PDF existant
    // Pour l'instant, nous retournons simplement le chemin original
    // TODO: Implémenter la signature de PDF existant si nécessaire
    return filePath;
  }
}
