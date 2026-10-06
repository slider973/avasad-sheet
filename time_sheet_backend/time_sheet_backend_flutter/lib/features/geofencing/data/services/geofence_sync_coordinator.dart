import 'package:time_sheet/features/geofencing/data/services/day_mirror_store.dart';
import 'package:time_sheet/features/geofencing/data/services/geofence_service.dart';
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';
import 'package:time_sheet/features/geofencing/domain/entities/day_pointage_snapshot.dart';
import 'package:time_sheet/features/geofencing/domain/repositories/geofence_settings_repository.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import 'package:time_sheet/services/logger_service.dart';

/// Fait le lien entre les décisions prises en arrière-plan et l'écriture
/// réelle en base, qui ne peut avoir lieu que dans l'application.
///
/// À appeler au démarrage, après l'initialisation de PowerSync :
/// l'isolate d'arrière-plan n'a pu qu'empiler ses décisions, c'est ici
/// qu'elles deviennent de vrais pointages.
class GeofenceSyncCoordinator {
  final GeofenceSettingsRepository _settingsRepository;
  final GeofenceService _geofenceService;
  final DayMirrorStore _mirrorStore;

  const GeofenceSyncCoordinator({
    required GeofenceSettingsRepository settingsRepository,
    required GeofenceService geofenceService,
    DayMirrorStore mirrorStore = const DayMirrorStore(),
  })  : _settingsRepository = settingsRepository,
        _geofenceService = geofenceService,
        _mirrorStore = mirrorStore;

  /// Réaligne les zones surveillées et rejoue les décisions en attente.
  Future<void> onAppStart(TimeSheetBloc bloc) async {
    final settings = await _settingsRepository.load();
    if (!settings.enabled) return;

    try {
      await _geofenceService.initialize();
      await _geofenceService.syncZones(settings);
    } catch (e) {
      logger.e('[Geofencing] Synchronisation des zones impossible : $e');
    }

    await replayPendingDecisions(bloc);
  }

  /// Transforme chaque décision empilée en événement de pointage.
  Future<int> replayPendingDecisions(TimeSheetBloc bloc) async {
    final decisions = await _mirrorStore.drainPendingDecisions();
    if (decisions.isEmpty) return 0;

    // Ordre chronologique : une reprise ne doit jamais précéder la pause qui
    // l'a provoquée.
    decisions.sort((a, b) => a.at.compareTo(b.at));

    var applied = 0;
    for (final decision in decisions) {
      final event = _toEvent(decision);
      if (event == null) continue;
      bloc.add(event);
      applied++;
      logger.i('[Geofencing] Pointage rejoué : ${decision.action.name} à '
          '${DayMirrorStore.formatTime(decision.at)}');
    }
    return applied;
  }

  TimeSheetEvent? _toEvent(AttendanceDecision decision) =>
      switch (decision.action) {
        AttendanceAction.clockIn => TimeSheetEnterEvent(decision.at),
        AttendanceAction.startBreak => TimeSheetStartBreakEvent(decision.at),
        AttendanceAction.endBreak => TimeSheetEndBreakEvent(decision.at),
        AttendanceAction.clockOut ||
        AttendanceAction.reconcile =>
          TimeSheetOutEvent(decision.at),
        _ => null,
      };

  /// Met à jour le miroir lu par l'isolate d'arrière-plan.
  ///
  /// À appeler après chaque pointage manuel : sans cela, l'arrière-plan
  /// raisonnerait sur un état périmé et pourrait pointer deux fois.
  Future<void> refreshMirror(TimesheetEntry entry, {DateTime? day}) async {
    final jour = day ?? DateTime.now();
    await _mirrorStore.write(
      DayPointageSnapshot(
        startMorning: entry.startMorning,
        endMorning: entry.endMorning,
        startAfternoon: entry.startAfternoon,
        endAfternoon: entry.endAfternoon,
      ),
      jour,
    );
  }
}
