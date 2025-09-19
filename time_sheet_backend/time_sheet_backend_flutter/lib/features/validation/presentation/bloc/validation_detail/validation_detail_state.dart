part of 'validation_detail_bloc.dart';

/// États pour le BLoC de détail de validation
abstract class ValidationDetailState extends Equatable {
  const ValidationDetailState();

  @override
  List<Object?> get props => [];
}

/// État initial
class ValidationDetailInitial extends ValidationDetailState {}

/// Chargement en cours
class ValidationDetailLoading extends ValidationDetailState {}

/// Détail chargé
class ValidationDetailLoaded extends ValidationDetailState {
  final ValidationRequest validation;

  const ValidationDetailLoaded(this.validation);

  @override
  List<Object> get props => [validation];
}

/// Détail chargé avec données timesheet
class ValidationDetailWithTimesheetLoaded extends ValidationDetailState {
  final ValidationRequest validation;
  final Map<String, dynamic> timesheetData;

  const ValidationDetailWithTimesheetLoaded({
    required this.validation,
    required this.timesheetData,
  });

  @override
  List<Object> get props => [validation, timesheetData];
}

/// Succès d'une action
class ValidationDetailSuccess extends ValidationDetailState {
  final String message;

  const ValidationDetailSuccess(this.message);

  @override
  List<Object> get props => [message];
}

/// PDF téléchargé
class ValidationDetailPdfDownloaded extends ValidationDetailState {
  final Uint8List pdfBytes;
  final String fileName;

  const ValidationDetailPdfDownloaded({
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  List<Object> get props => [pdfBytes, fileName];
}

/// Erreur
class ValidationDetailError extends ValidationDetailState {
  final String message;

  const ValidationDetailError(this.message);

  @override
  List<Object> get props => [message];
}
