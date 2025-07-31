part of 'validation_list_bloc.dart';

/// États pour le BLoC de liste des validations
abstract class ValidationListState extends Equatable {
  const ValidationListState();
  
  @override
  List<Object?> get props => [];
}

/// État initial
class ValidationListInitial extends ValidationListState {}

/// Chargement en cours
class ValidationListLoading extends ValidationListState {}

/// Validations chargées
class ValidationListLoaded extends ValidationListState {
  final List<ValidationRequest> validations;
  final List<ValidationRequest> allValidations;
  final ValidationFilters currentFilters;
  final ValidationViewType viewType;
  
  const ValidationListLoaded({
    required this.validations,
    required this.allValidations,
    required this.currentFilters,
    required this.viewType,
  });
  
  /// Statistiques
  int get pendingCount => allValidations.where((v) => v.isPending).length;
  int get approvedCount => allValidations.where((v) => v.isApproved).length;
  int get rejectedCount => allValidations.where((v) => v.isRejected).length;
  
  ValidationListLoaded copyWith({
    List<ValidationRequest>? validations,
    List<ValidationRequest>? allValidations,
    ValidationFilters? currentFilters,
    ValidationViewType? viewType,
  }) {
    return ValidationListLoaded(
      validations: validations ?? this.validations,
      allValidations: allValidations ?? this.allValidations,
      currentFilters: currentFilters ?? this.currentFilters,
      viewType: viewType ?? this.viewType,
    );
  }
  
  @override
  List<Object> get props => [validations, allValidations, currentFilters, viewType];
}

/// Erreur
class ValidationListError extends ValidationListState {
  final String message;
  
  const ValidationListError(this.message);
  
  @override
  List<Object> get props => [message];
}