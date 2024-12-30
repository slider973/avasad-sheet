part of 'anomaly_bloc.dart';

sealed class AnomalyEvent extends Equatable {
  const AnomalyEvent();
}

class DetectAnomalies extends AnomalyEvent {

  const DetectAnomalies();

  @override
  List<Object> get props => [];
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