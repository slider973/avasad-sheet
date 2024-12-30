import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../services/anomaly_detector_config.dart';
import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../data/models/anomalies/anomalies.dart';
import '../../../../../data/repositories/anomaly_repository_impl.dart';
import '../../../../../strategies/anomaly_detector.dart';
import '../../../../../use_cases/detect_anomalies_usecase.dart';

part 'anomaly_event.dart';
part 'anomaly_state.dart';

class AnomalyBloc extends Bloc<AnomalyEvent, AnomalyState> {
  final DetectAnomaliesUseCase detectAnomaliesUseCase;
  final PreferencesBloc preferencesBloc;
  final Map<String, AnomalyDetector> allDetectors;
  final AnomalyRepository anomalyRepository; // Ajout du repository

  AnomalyBloc({
    required this.detectAnomaliesUseCase,
    required this.preferencesBloc,
    required this.allDetectors,
    required this.anomalyRepository,
  }) : super(AnomalyInitial()) {
    on<DetectAnomalies>(_onDetectAnomalies);
    on<LoadActiveDetectors>(_onLoadActiveDetectors);
    on<ToggleDetector>(_onToggleDetector);
    on<MarkAnomalyResolved>(_onMarkResolved);
  }
  Future<void> _onMarkResolved(MarkAnomalyResolved event, Emitter<AnomalyState> emit) async {
    try {
      // Marque l'anomalie comme résolue et rafraîchit la liste
      await anomalyRepository.markResolved(event.anomalyId);
      add(DetectAnomalies());
    } catch (e) {
      emit(AnomalyError("Erreur lors de la résolution de l'anomalie : ${e.toString()}"));
    }
  }

  Future<void> _onDetectAnomalies(DetectAnomalies event, Emitter<AnomalyState> emit) async {
    emit(AnomalyLoading());
    try {
      final anomalies = await anomalyRepository.getAnomalies(); // List<AnomalyModel>
      if (anomalies.isEmpty) {
        emit(const AnomalyLoaded([]));
      } else {
        emit(AnomalyLoaded(anomalies));
      }
    } catch (e) {
      emit(AnomalyError("Erreur lors de la détection des anomalies : $e"));
    }
  }

  Future<void> _onLoadActiveDetectors(LoadActiveDetectors event, Emitter<AnomalyState> emit) async {
    try {
      final activeDetectorIds = await AnomalyDetectorConfig.getActiveDetectors(preferencesBloc);
      emit(ActiveDetectorsLoaded(activeDetectorIds));
    } catch (e) {
      emit(AnomalyError("Erreur lors du chargement des détecteurs actifs : $e"));
    }
  }

  Future<void> _onToggleDetector(ToggleDetector event, Emitter<AnomalyState> emit) async {
    try {
      if (event.isActive) {
        await AnomalyDetectorConfig.addDetector(preferencesBloc, event.detectorId);
      } else {
        await AnomalyDetectorConfig.removeDetector(preferencesBloc, event.detectorId);
      }
      add(LoadActiveDetectors());
    } catch (e) {
      emit(AnomalyError("Erreur lors de la modification des détecteurs actifs : $e"));
    }
  }
}