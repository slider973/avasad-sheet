part of 'create_validation_bloc.dart';

/// États pour le BLoC de création de validation
abstract class CreateValidationState extends Equatable {
  const CreateValidationState();
  
  @override
  List<Object?> get props => [];
}

/// État initial
class CreateValidationInitial extends CreateValidationState {}

/// Chargement des managers
class CreateValidationLoading extends CreateValidationState {}

/// Formulaire prêt
class CreateValidationForm extends CreateValidationState {
  final List<Manager> availableManagers;
  final Manager? selectedManager;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final Uint8List? pdfBytes;
  final String? pdfFileName;
  final String? error;
  
  const CreateValidationForm({
    required this.availableManagers,
    this.selectedManager,
    this.periodStart,
    this.periodEnd,
    this.pdfBytes,
    this.pdfFileName,
    this.error,
  });
  
  bool get isValid => 
      selectedManager != null &&
      periodStart != null &&
      periodEnd != null &&
      pdfBytes != null;
  
  CreateValidationForm copyWith({
    List<Manager>? availableManagers,
    Manager? selectedManager,
    DateTime? periodStart,
    DateTime? periodEnd,
    Uint8List? pdfBytes,
    String? pdfFileName,
    String? error,
  }) {
    return CreateValidationForm(
      availableManagers: availableManagers ?? this.availableManagers,
      selectedManager: selectedManager ?? this.selectedManager,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      pdfBytes: pdfBytes ?? this.pdfBytes,
      pdfFileName: pdfFileName ?? this.pdfFileName,
      error: error,
    );
  }
  
  @override
  List<Object?> get props => [
    availableManagers,
    selectedManager,
    periodStart,
    periodEnd,
    pdfBytes,
    pdfFileName,
    error,
  ];
}

/// Soumission en cours
class CreateValidationSubmitting extends CreateValidationState {}

/// Validation créée avec succès
class CreateValidationSuccess extends CreateValidationState {
  final ValidationRequest validation;
  
  const CreateValidationSuccess(this.validation);
  
  @override
  List<Object> get props => [validation];
}

/// Erreur
class CreateValidationError extends CreateValidationState {
  final String message;
  
  const CreateValidationError(this.message);
  
  @override
  List<Object> get props => [message];
}