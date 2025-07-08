part of 'anomaly_bloc.dart';

sealed class AnomalyState extends Equatable {
  const AnomalyState();
}

class AnomalyInitial extends AnomalyState {
  @override
  List<Object?> get props => [];
}

class AnomalyLoading extends AnomalyState {
  @override
  List<Object?> get props => [];
}
class AnomalyLoaded extends AnomalyState {
  final List<AnomalyModel> anomalies;

  const AnomalyLoaded(this.anomalies);

  @override
  List<Object> get props => [anomalies];
}

class AnomalyDetected extends AnomalyState {
  final List<AnomalyModel> anomalies;

  const AnomalyDetected(this.anomalies);

  @override
  List<Object> get props => [anomalies];
}

class AnomalyError extends AnomalyState {
  final String message;

  const AnomalyError(this.message);

  @override
  List<Object> get props => [message];
}

class ActiveDetectorsLoaded extends AnomalyState {
  final List<String> activeDetectorIds;

  const ActiveDetectorsLoaded(this.activeDetectorIds);

  @override
  List<Object> get props => [activeDetectorIds];
}

/// Nouvel état pour la vérification des anomalies avant génération PDF
class PdfAnomalyCheckCompleted extends AnomalyState {
  final List<String> criticalAnomaliesMessages;
  final List<String> minorAnomaliesMessages;
  final int month;
  final int year;

  const PdfAnomalyCheckCompleted({
    required this.criticalAnomaliesMessages,
    required this.minorAnomaliesMessages,
    required this.month,
    required this.year,
  });

  bool get hasCriticalAnomalies => criticalAnomaliesMessages.isNotEmpty;
  bool get hasMinorAnomalies => minorAnomaliesMessages.isNotEmpty;
  bool get hasAnyAnomalies => hasCriticalAnomalies || hasMinorAnomalies;

  @override
  List<Object> get props => [criticalAnomaliesMessages, minorAnomaliesMessages, month, year];
}