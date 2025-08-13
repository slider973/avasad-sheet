part of 'anomaly_bloc.dart';

sealed class AnomalyEvent extends Equatable {
  const AnomalyEvent();
}

class DetectAnomalies extends AnomalyEvent {
  final bool forceRegenerate;

  const DetectAnomalies({this.forceRegenerate = false});

  @override
  List<Object> get props => [forceRegenerate];
}
class LoadActiveDetectors extends AnomalyEvent {
  @override
  List<Object?> get props => [];
}
class ToggleDetector extends AnomalyEvent {
  final String detectorId;
  final bool isActive;

  const ToggleDetector(this.detectorId, this.isActive);

  @override
  List<Object> get props => [detectorId, isActive];
}
class MarkAnomalyResolved extends AnomalyEvent {
  final int anomalyId;

  const MarkAnomalyResolved(this.anomalyId);

  @override
  List<Object> get props => [anomalyId];
}

/// Nouvel événement pour vérifier les anomalies avant génération PDF
class CheckAnomaliesForPdfGeneration extends AnomalyEvent {
  final int month;
  final int year;

  const CheckAnomaliesForPdfGeneration(this.month, this.year);

  @override
  List<Object> get props => [month, year];
}

/// Événement pour détecter les anomalies avec compensation hebdomadaire
class DetectAnomaliesWithCompensation extends AnomalyEvent {
  final int month;
  final int year;

  const DetectAnomaliesWithCompensation({
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [month, year];
}