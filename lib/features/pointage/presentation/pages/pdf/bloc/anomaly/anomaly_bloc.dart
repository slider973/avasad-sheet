import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../services/anomaly_detector_config.dart';
import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../data/models/anomalies/anomalies.dart';
import '../../../../../data/repositories/anomaly_repository_impl.dart';
import '../../../../../domain/strategies/anomaly_detector.dart';
import '../../../../../domain/use_cases/detect_anomalies_usecase.dart';
import '../../../../../domain/services/anomaly_detection_service.dart';
import '../../../../../domain/repositories/timesheet_repository.dart';
import '../../../../../../../services/anomaly/anomaly_service.dart';

part 'anomaly_event.dart';
part 'anomaly_state.dart';

class AnomalyBloc extends Bloc<AnomalyEvent, AnomalyState> {
  final DetectAnomaliesUseCase detectAnomaliesUseCase;
  final PreferencesBloc preferencesBloc;
  final Map<String, AnomalyDetector> allDetectors;
  final AnomalyRepository anomalyRepository; // Ajout du repository
  final AnomalyDetectionService newAnomalyDetectionService;
  final TimesheetRepository timesheetRepository;
  final AnomalyService anomalyService;

  AnomalyBloc({
    required this.detectAnomaliesUseCase,
    required this.preferencesBloc,
    required this.allDetectors,
    required this.anomalyRepository,
    required this.newAnomalyDetectionService,
    required this.timesheetRepository,
    required this.anomalyService,
  }) : super(AnomalyInitial()) {
    on<DetectAnomalies>(_onDetectAnomalies);
    on<LoadActiveDetectors>(_onLoadActiveDetectors);
    on<ToggleDetector>(_onToggleDetector);
    on<MarkAnomalyResolved>(_onMarkResolved);
    on<CheckAnomaliesForPdfGeneration>(_onCheckAnomaliesForPdfGeneration);
  }
  Future<void> _onMarkResolved(MarkAnomalyResolved event, Emitter<AnomalyState> emit) async {
    try {
      // Marque l'anomalie comme résolue et rafraîchit la liste
      await anomalyRepository.markResolved(event.anomalyId);
      add(const DetectAnomalies(forceRegenerate: true));
    } catch (e) {
      emit(AnomalyError("Erreur lors de la résolution de l'anomalie : ${e.toString()}"));
    }
  }

  Future<void> _onDetectAnomalies(DetectAnomalies event, Emitter<AnomalyState> emit) async {
    emit(AnomalyLoading());
    try {
      // D'abord récupérer les anomalies existantes
      final existingAnomalies = await anomalyRepository.getAnomalies();
      
      // Seulement générer de nouvelles anomalies si forcé ou si aucune n'existe
      if (event.forceRegenerate || existingAnomalies.isEmpty) {
        await anomalyService.createAnomaliesForCurrentMonth();
        // Récupérer les anomalies après génération
        final anomalies = await anomalyRepository.getAnomalies();
        emit(AnomalyLoaded(anomalies));
      } else {
        // Utiliser les anomalies existantes
        emit(AnomalyLoaded(existingAnomalies));
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

  /// Nouvelle méthode pour vérifier les anomalies avant génération PDF
  Future<void> _onCheckAnomaliesForPdfGeneration(
    CheckAnomaliesForPdfGeneration event, 
    Emitter<AnomalyState> emit
  ) async {
    emit(AnomalyLoading());
    try {
      // Récupérer les entrées du mois spécifié
      final entries = await timesheetRepository.findEntriesFromMonthOf(event.month, event.year);
      
      // Détecter les anomalies avec compensation hebdomadaire
      final anomaliesResults = await newAnomalyDetectionService.detectAnomaliesWithWeeklyCompensation(entries);
      
      // Rassembler toutes les anomalies
      final allAnomalies = <String>[];
      final criticalAnomalies = <String>[];
      final minorAnomalies = <String>[];
      
      for (final entryAnomalies in anomaliesResults.values) {
        for (final anomaly in entryAnomalies) {
          final message = '${anomaly.type.displayName}: ${anomaly.description}';
          allAnomalies.add(message);
          
          if (anomaly.severity.priority >= 3) { // high et critical
            criticalAnomalies.add(message);
          } else {
            minorAnomalies.add(message);
          }
        }
      }
      
      emit(PdfAnomalyCheckCompleted(
        criticalAnomaliesMessages: criticalAnomalies,
        minorAnomaliesMessages: minorAnomalies,
        month: event.month,
        year: event.year,
      ));
      
    } catch (e) {
      emit(AnomalyError("Erreur lors de la vérification des anomalies : $e"));
    }
  }
}