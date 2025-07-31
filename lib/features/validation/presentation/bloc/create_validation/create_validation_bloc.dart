import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/use_cases/create_validation_request_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/get_available_managers_usecase.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';
import 'package:time_sheet/core/services/supabase/supabase_service.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';

part 'create_validation_event.dart';
part 'create_validation_state.dart';

/// BLoC pour créer une demande de validation
class CreateValidationBloc extends Bloc<CreateValidationEvent, CreateValidationState> {
  final CreateValidationRequestUseCase createValidationRequest;
  final GetAvailableManagersUseCase getAvailableManagers;
  final SupabaseService supabaseService;
  final GetUserPreferenceUseCase getUserPreference;
  
  CreateValidationBloc({
    required this.createValidationRequest,
    required this.getAvailableManagers,
    required this.supabaseService,
    required this.getUserPreference,
  }) : super(CreateValidationInitial()) {
    on<LoadManagers>(_onLoadManagers);
    on<SelectManager>(_onSelectManager);
    on<SelectPeriod>(_onSelectPeriod);
    on<SetPdfData>(_onSetPdfData);
    on<SubmitValidation>(_onSubmitValidation);
    on<ResetForm>(_onResetForm);
  }
  
  Future<void> _onLoadManagers(
    LoadManagers event,
    Emitter<CreateValidationState> emit,
  ) async {
    emit(CreateValidationLoading());
    
    try {
      // Récupérer l'ID utilisateur depuis les préférences
      final firstName = await getUserPreference.execute('firstName') ?? '';
      final lastName = await getUserPreference.execute('lastName') ?? '';
      
      if (firstName.isEmpty || lastName.isEmpty) {
        emit(const CreateValidationError('Veuillez configurer votre nom dans les paramètres'));
        return;
      }
      
      // Utiliser email comme ID unique
      final userId = '${firstName.toLowerCase()}_${lastName.toLowerCase()}';
      
      final result = await getAvailableManagers(userId);
      
      result.fold(
        (failure) => emit(CreateValidationError((failure as Failure).message)),
        (managers) {
          if (managers.isEmpty) {
            emit(const CreateValidationError('Aucun manager disponible'));
          } else {
            emit(CreateValidationForm(availableManagers: managers));
          }
        },
      );
    } catch (e) {
      emit(CreateValidationError('Erreur inattendue: $e'));
    }
  }
  
  void _onSelectManager(
    SelectManager event,
    Emitter<CreateValidationState> emit,
  ) {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;
      emit(currentState.copyWith(selectedManager: event.manager));
    }
  }
  
  void _onSelectPeriod(
    SelectPeriod event,
    Emitter<CreateValidationState> emit,
  ) {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;
      
      // Valider les dates
      if (event.endDate.isBefore(event.startDate)) {
        emit(currentState.copyWith(
          error: 'La date de fin doit être après la date de début',
        ));
        return;
      }
      
      emit(currentState.copyWith(
        periodStart: event.startDate,
        periodEnd: event.endDate,
        error: null,
      ));
    }
  }
  
  void _onSetPdfData(
    SetPdfData event,
    Emitter<CreateValidationState> emit,
  ) {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;
      emit(currentState.copyWith(
        pdfBytes: event.pdfBytes,
        pdfFileName: event.fileName,
      ));
    }
  }
  
  Future<void> _onSubmitValidation(
    SubmitValidation event,
    Emitter<CreateValidationState> emit,
  ) async {
    if (state is CreateValidationForm) {
      final currentState = state as CreateValidationForm;
      
      // Valider le formulaire
      if (currentState.selectedManager == null) {
        emit(currentState.copyWith(error: 'Veuillez sélectionner un manager'));
        return;
      }
      
      if (currentState.periodStart == null || currentState.periodEnd == null) {
        emit(currentState.copyWith(error: 'Veuillez sélectionner une période'));
        return;
      }
      
      if (currentState.pdfBytes == null) {
        emit(currentState.copyWith(error: 'Veuillez générer le PDF'));
        return;
      }
      
      emit(CreateValidationSubmitting());
      
      try {
        // Récupérer l'ID utilisateur depuis les préférences
        final firstName = await getUserPreference.execute('firstName') ?? '';
        final lastName = await getUserPreference.execute('lastName') ?? '';
        
        if (firstName.isEmpty || lastName.isEmpty) {
          emit(const CreateValidationError('Veuillez configurer votre nom dans les paramètres'));
          return;
        }
        
        // Utiliser email comme ID unique
        final userId = '${firstName.toLowerCase()}_${lastName.toLowerCase()}';
        
        final params = CreateValidationParams(
          employeeId: userId,
          managerId: currentState.selectedManager!.id,
          periodStart: currentState.periodStart!,
          periodEnd: currentState.periodEnd!,
          pdfBytes: currentState.pdfBytes!,
        );
        
        final result = await createValidationRequest(params);
        
        result.fold(
          (failure) => emit(CreateValidationError((failure as Failure).message)),
          (validation) => emit(CreateValidationSuccess(validation)),
        );
      } catch (e) {
        emit(CreateValidationError('Erreur inattendue: $e'));
      }
    }
  }
  
  void _onResetForm(
    ResetForm event,
    Emitter<CreateValidationState> emit,
  ) {
    add(LoadManagers());
  }
}