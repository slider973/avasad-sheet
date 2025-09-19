part of 'validation_list_bloc.dart';

/// Événements pour le BLoC de liste des validations
abstract class ValidationListEvent extends Equatable {
  const ValidationListEvent();

  @override
  List<Object?> get props => [];
}

/// Charger les validations
class LoadValidations extends ValidationListEvent {
  final ValidationViewType viewType;
  final ValidationFilters filters;

  const LoadValidations({
    required this.viewType,
    this.filters = const ValidationFilters(),
  });

  @override
  List<Object?> get props => [viewType, filters];
}

/// Rafraîchir les validations
class RefreshValidations extends ValidationListEvent {
  const RefreshValidations();
}

/// Filtrer les validations
class FilterValidations extends ValidationListEvent {
  final ValidationFilters filters;

  const FilterValidations(this.filters);

  @override
  List<Object> get props => [filters];
}

/// Type de vue (employé ou manager)
enum ValidationViewType {
  employee,
  manager,
}

/// Filtres pour les validations
class ValidationFilters extends Equatable {
  final ValidationStatus? status;
  final DateTime? startDate;
  final DateTime? endDate;
  final SortBy sortBy;
  final bool? hasWeekendHours; // Nouveau filtre pour les heures de weekend

  const ValidationFilters({
    this.status,
    this.startDate,
    this.endDate,
    this.sortBy = SortBy.dateDesc,
    this.hasWeekendHours,
  });

  ValidationFilters copyWith({
    ValidationStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    SortBy? sortBy,
    bool? hasWeekendHours,
  }) {
    return ValidationFilters(
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
      hasWeekendHours: hasWeekendHours ?? this.hasWeekendHours,
    );
  }

  @override
  List<Object?> get props =>
      [status, startDate, endDate, sortBy, hasWeekendHours];
}

/// Options de tri
enum SortBy {
  dateDesc,
  dateAsc,
  periodDesc,
  periodAsc,
}
