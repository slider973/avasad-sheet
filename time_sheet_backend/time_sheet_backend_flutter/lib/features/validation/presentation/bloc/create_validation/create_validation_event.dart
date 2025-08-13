part of 'create_validation_bloc.dart';

/// Événements pour le BLoC de création de validation
abstract class CreateValidationEvent extends Equatable {
  const CreateValidationEvent();
  
  @override
  List<Object?> get props => [];
}

/// Charger les managers disponibles
class LoadManagers extends CreateValidationEvent {
  const LoadManagers();
}

/// Sélectionner un manager
class SelectManager extends CreateValidationEvent {
  final Manager manager;
  
  const SelectManager(this.manager);
  
  @override
  List<Object> get props => [manager];
}

/// Sélectionner une période
class SelectPeriod extends CreateValidationEvent {
  final DateTime startDate;
  final DateTime endDate;
  
  const SelectPeriod({
    required this.startDate,
    required this.endDate,
  });
  
  @override
  List<Object> get props => [startDate, endDate];
}

/// Sélectionner un PDF généré
class SelectGeneratedPdf extends CreateValidationEvent {
  final GeneratedPdf pdf;
  
  const SelectGeneratedPdf(this.pdf);
  
  @override
  List<Object> get props => [pdf];
}

/// Définir les données PDF
class SetPdfData extends CreateValidationEvent {
  final Uint8List pdfBytes;
  final String fileName;
  
  const SetPdfData({
    required this.pdfBytes,
    required this.fileName,
  });
  
  @override
  List<Object> get props => [pdfBytes, fileName];
}

/// Soumettre la validation
class SubmitValidation extends CreateValidationEvent {
  const SubmitValidation();
}

/// Réinitialiser le formulaire
class ResetForm extends CreateValidationEvent {
  const ResetForm();
}