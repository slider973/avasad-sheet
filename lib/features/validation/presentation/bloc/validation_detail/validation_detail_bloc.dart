import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/use_cases/get_employee_validations_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/approve_validation_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/reject_validation_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/download_validation_pdf_usecase.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';

part 'validation_detail_event.dart';
part 'validation_detail_state.dart';

/// BLoC pour gérer le détail d'une validation
class ValidationDetailBloc extends Bloc<ValidationDetailEvent, ValidationDetailState> {
  final ValidationRepository repository;
  final ApproveValidationUseCase approveValidation;
  final RejectValidationUseCase rejectValidation;
  final DownloadValidationPdfUseCase downloadPdf;
  
  ValidationDetailBloc({
    required this.repository,
    required this.approveValidation,
    required this.rejectValidation,
    required this.downloadPdf,
  }) : super(ValidationDetailInitial()) {
    on<LoadValidationDetail>(_onLoadValidationDetail);
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
        (failure) => emit(ValidationDetailError((failure as Failure).message)),
        (validation) => emit(ValidationDetailLoaded(validation)),
      );
    } catch (e) {
      emit(ValidationDetailError('Erreur inattendue: $e'));
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
          emit(ValidationDetailError((failure as Failure).message));
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
          emit(ValidationDetailError((failure as Failure).message));
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
      final result = await downloadPdf(event.validationId);
      
      result.fold(
        (failure) => emit(ValidationDetailError((failure as Failure).message)),
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