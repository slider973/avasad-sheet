part of 'validation_detail_bloc.dart';

/// Événements pour le BLoC de détail de validation
abstract class ValidationDetailEvent extends Equatable {
  const ValidationDetailEvent();
  
  @override
  List<Object?> get props => [];
}

/// Charger le détail d'une validation
class LoadValidationDetail extends ValidationDetailEvent {
  final String validationId;
  
  const LoadValidationDetail(this.validationId);
  
  @override
  List<Object> get props => [validationId];
}

/// Approuver une validation
class ApproveValidation extends ValidationDetailEvent {
  final String validationId;
  final String managerSignature;
  final String? comment;
  
  const ApproveValidation({
    required this.validationId,
    required this.managerSignature,
    this.comment,
  });
  
  @override
  List<Object?> get props => [validationId, managerSignature, comment];
}

/// Rejeter une validation
class RejectValidation extends ValidationDetailEvent {
  final String validationId;
  final String comment;
  
  const RejectValidation({
    required this.validationId,
    required this.comment,
  });
  
  @override
  List<Object> get props => [validationId, comment];
}

/// Télécharger le PDF d'une validation
class DownloadValidationPdf extends ValidationDetailEvent {
  final String validationId;
  
  const DownloadValidationPdf(this.validationId);
  
  @override
  List<Object> get props => [validationId];
}