import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/use_cases/get_employee_validations_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/approve_validation_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/reject_validation_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/download_validation_pdf_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/get_validation_timesheet_data_usecase.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';

part 'validation_detail_event.dart';
part 'validation_detail_state.dart';

/// BLoC pour gérer le détail d'une validation
class ValidationDetailBloc
    extends Bloc<ValidationDetailEvent, ValidationDetailState> {
  final ValidationRepository repository;
  final ApproveValidationUseCase approveValidation;
  final RejectValidationUseCase rejectValidation;
  final DownloadValidationPdfUseCase downloadPdf;
  final GetValidationTimesheetDataUseCase getTimesheetData;

  ValidationDetailBloc({
    required this.repository,
    required this.approveValidation,
    required this.rejectValidation,
    required this.downloadPdf,
    required this.getTimesheetData,
  }) : super(ValidationDetailInitial()) {
    on<LoadValidationDetail>(_onLoadValidationDetail);
    on<LoadValidationTimesheetData>(_onLoadValidationTimesheetData);
    on<ApproveValidation>(_onApproveValidation);
    on<RejectValidation>(_onRejectValidation);
    on<DownloadValidationPdf>(_onDownloadValidationPdf);
  }

  Future<void> _onLoadValidationDetail(
    LoadValidationDetail event,
    Emitter<ValidationDetailState> emit,
  ) async {
    emit(ValidationDetailLoading());

    try {
      final result = await repository.getValidationRequest(event.validationId);

      result.fold(
        (failure) => emit(ValidationDetailError((failure).message)),
        (validation) => emit(ValidationDetailLoaded(validation)),
      );
    } catch (e) {
      emit(ValidationDetailError('Erreur inattendue: $e'));
    }
  }

  Future<void> _onLoadValidationTimesheetData(
    LoadValidationTimesheetData event,
    Emitter<ValidationDetailState> emit,
  ) async {
    final currentState = state;

    // Si on a déjà les données de validation, on les garde
    ValidationRequest? validation;
    if (currentState is ValidationDetailLoaded) {
      validation = currentState.validation;
    } else if (currentState is ValidationDetailWithTimesheetLoaded) {
      validation = currentState.validation;
    }

    // Si on n'a pas encore les données de validation, les charger d'abord
    if (validation == null) {
      emit(ValidationDetailLoading());

      final validationResult =
          await repository.getValidationRequest(event.validationId);
      final validationEither = validationResult.fold(
        (failure) => null,
        (val) => val,
      );

      if (validationEither == null) {
        emit(ValidationDetailError('Impossible de charger la validation'));
        return;
      }

      validation = validationEither;
    }

    try {
      // Charger les données timesheet
      final timesheetResult = await getTimesheetData(event.validationId);

      timesheetResult.fold(
        (failure) => emit(ValidationDetailError(
            'Impossible de charger les données timesheet: ${failure.message}')),
        (timesheetData) => emit(ValidationDetailWithTimesheetLoaded(
          validation: validation!,
          timesheetData: timesheetData,
        )),
      );
    } catch (e) {
      emit(ValidationDetailError(
          'Erreur lors du chargement des données timesheet: $e'));
    }
  }

  Future<void> _onApproveValidation(
    ApproveValidation event,
    Emitter<ValidationDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ValidationDetailLoaded) return;

    emit(ValidationDetailLoading());

    try {
      final params = ApproveValidationParams(
        validationId: event.validationId,
        managerSignature: event.managerSignature,
        comment: event.comment,
      );

      final result = await approveValidation(params);

      result.fold(
        (failure) {
          emit(currentState);
          emit(ValidationDetailError((failure).message));
        },
        (validation) {
          emit(ValidationDetailLoaded(validation));
          emit(ValidationDetailSuccess('Validation approuvée avec succès'));
        },
      );
    } catch (e) {
      emit(currentState);
      emit(ValidationDetailError('Erreur inattendue: $e'));
    }
  }

  Future<void> _onRejectValidation(
    RejectValidation event,
    Emitter<ValidationDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ValidationDetailLoaded) return;

    emit(ValidationDetailLoading());

    try {
      final params = RejectValidationParams(
        validationId: event.validationId,
        comment: event.comment,
      );

      final result = await rejectValidation(params);

      result.fold(
        (failure) {
          emit(currentState);
          emit(ValidationDetailError((failure).message));
        },
        (validation) {
          emit(ValidationDetailLoaded(validation));
          emit(ValidationDetailSuccess('Validation rejetée'));
        },
      );
    } catch (e) {
      emit(currentState);
      emit(ValidationDetailError('Erreur inattendue: $e'));
    }
  }

  Future<void> _onDownloadValidationPdf(
    DownloadValidationPdf event,
    Emitter<ValidationDetailState> emit,
  ) async {
    final currentState = state;

    try {
      final params = DownloadPdfParams(
        validationId: event.validationId,
        managerSignature: event.managerSignature,
      );

      final result = await downloadPdf(params);

      result.fold(
        (failure) => emit(ValidationDetailError((failure).message)),
        (pdfBytes) => emit(ValidationDetailPdfDownloaded(
          pdfBytes: pdfBytes,
          fileName: 'timesheet_${event.validationId}.pdf',
        )),
      );

      // Restaurer l'état précédent après le téléchargement
      if (currentState is ValidationDetailLoaded) {
        emit(currentState);
      }
    } catch (e) {
      emit(ValidationDetailError('Erreur lors du téléchargement: $e'));
      if (currentState is ValidationDetailLoaded) {
        emit(currentState);
      }
    }
  }
}
