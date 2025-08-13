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
  final List<GeneratedPdf> availablePdfs;
  final Manager? selectedManager;
  final GeneratedPdf? selectedPdf;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final Uint8List? pdfBytes;
  final String? pdfFileName;
  final String? error;
  
  const CreateValidationForm({
    required this.availableManagers,
    required this.availablePdfs,
    this.selectedManager,
    this.selectedPdf,
    this.periodStart,
    this.periodEnd,
    this.pdfBytes,
    this.pdfFileName,
    this.error,
  });
  
  bool get isValid => 
      selectedManager != null &&
      selectedPdf != null &&
      pdfBytes != null;
  
  CreateValidationForm copyWith({
    List<Manager>? availableManagers,
    List<GeneratedPdf>? availablePdfs,
    Manager? selectedManager,
    GeneratedPdf? selectedPdf,
    DateTime? periodStart,
    DateTime? periodEnd,
    Uint8List? pdfBytes,
    String? pdfFileName,
    String? error,
    bool clearPdf = false,
  }) {
    return CreateValidationForm(
      availableManagers: availableManagers ?? this.availableManagers,
      availablePdfs: availablePdfs ?? this.availablePdfs,
      selectedManager: selectedManager ?? this.selectedManager,
      selectedPdf: clearPdf ? null : (selectedPdf ?? this.selectedPdf),
      periodStart: clearPdf ? null : (periodStart ?? this.periodStart),
      periodEnd: clearPdf ? null : (periodEnd ?? this.periodEnd),
      pdfBytes: clearPdf ? null : (pdfBytes ?? this.pdfBytes),
      pdfFileName: clearPdf ? null : (pdfFileName ?? this.pdfFileName),
      error: error,
    );
  }
  
  @override
  List<Object?> get props => [
    availableManagers,
    availablePdfs,
    selectedManager,
    selectedPdf,
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