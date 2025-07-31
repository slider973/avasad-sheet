import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/use_cases/get_employee_validations_usecase.dart';
import 'package:time_sheet/features/validation/domain/use_cases/get_manager_validations_usecase.dart';
import 'package:time_sheet/core/services/supabase/supabase_service.dart';

part 'validation_list_event.dart';
part 'validation_list_state.dart';

/// BLoC pour gérer la liste des validations
class ValidationListBloc extends Bloc<ValidationListEvent, ValidationListState> {
  final GetEmployeeValidationsUseCase getEmployeeValidations;
  final GetManagerValidationsUseCase getManagerValidations;
  final SupabaseService supabaseService;
  
  ValidationListBloc({
    required this.getEmployeeValidations,
    required this.getManagerValidations,
    required this.supabaseService,
  }) : super(ValidationListInitial()) {
    on<LoadValidations>(_onLoadValidations);
    on<RefreshValidations>(_onRefreshValidations);
    on<FilterValidations>(_onFilterValidations);
  }
  
  Future<void> _onLoadValidations(
    LoadValidations event,
    Emitter<ValidationListState> emit,
  ) async {
    emit(ValidationListLoading());
    
    try {
      final userId = supabaseService.currentUserId;
      if (userId == null) {
        emit(const ValidationListError('Utilisateur non connecté'));
        return;
      }
      
      // Déterminer le type de liste à charger
      final result = event.viewType == ValidationViewType.employee
          ? await getEmployeeValidations(userId)
          : await getManagerValidations(userId);
      
      result.fold(
        (failure) => emit(ValidationListError(failure.message)),
        (validations) {
          // Appliquer les filtres si nécessaire
          final filtered = _applyFilters(validations, event.filters);
          emit(ValidationListLoaded(
            validations: filtered,
            allValidations: validations,
            currentFilters: event.filters,
            viewType: event.viewType,
          ));
        },
      );
    } catch (e) {
      emit(ValidationListError('Erreur inattendue: $e'));
    }
  }
  
  Future<void> _onRefreshValidations(
    RefreshValidations event,
    Emitter<ValidationListState> emit,
  ) async {
    if (state is ValidationListLoaded) {
      final currentState = state as ValidationListLoaded;
      add(LoadValidations(
        viewType: currentState.viewType,
        filters: currentState.currentFilters,
      ));
    }
  }
  
  void _onFilterValidations(
    FilterValidations event,
    Emitter<ValidationListState> emit,
  ) {
    if (state is ValidationListLoaded) {
      final currentState = state as ValidationListLoaded;
      final filtered = _applyFilters(
        currentState.allValidations,
        event.filters,
      );
      
      emit(currentState.copyWith(
        validations: filtered,
        currentFilters: event.filters,
      ));
    }
  }
  
  List<ValidationRequest> _applyFilters(
    List<ValidationRequest> validations,
    ValidationFilters filters,
  ) {
    var filtered = validations;
    
    // Filtrer par statut
    if (filters.status != null) {
      filtered = filtered.where((v) => v.status == filters.status).toList();
    }
    
    // Filtrer par période
    if (filters.startDate != null) {
      filtered = filtered.where((v) => 
        v.periodStart.isAfter(filters.startDate!) ||
        v.periodStart.isAtSameMomentAs(filters.startDate!)
      ).toList();
    }
    
    if (filters.endDate != null) {
      filtered = filtered.where((v) => 
        v.periodEnd.isBefore(filters.endDate!) ||
        v.periodEnd.isAtSameMomentAs(filters.endDate!)
      ).toList();
    }
    
    // Trier
    switch (filters.sortBy) {
      case SortBy.dateDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortBy.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortBy.periodDesc:
        filtered.sort((a, b) => b.periodStart.compareTo(a.periodStart));
        break;
      case SortBy.periodAsc:
        filtered.sort((a, b) => a.periodStart.compareTo(b.periodStart));
        break;
    }
    
    return filtered;
  }
}