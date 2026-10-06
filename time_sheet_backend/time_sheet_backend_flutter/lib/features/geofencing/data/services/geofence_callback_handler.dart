import 'package:native_geofence/native_geofence.dart' as ng;
import 'package:time_sheet/features/geofencing/data/repositories/geofence_preferences_store.dart';
import 'package:time_sheet/features/geofencing/data/repositories/geofence_runtime_state_repository_impl.dart';
import 'package:time_sheet/features/geofencing/data/repositories/geofence_settings_repository_impl.dart';
import 'package:time_sheet/features/geofencing/data/services/day_mirror_store.dart';
import 'package:time_sheet/features/geofencing/data/services/geofence_notifier.dart';
import 'package:time_sheet/features/geofencing/data/services/geofence_service.dart';
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_event.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';
import 'package:time_sheet/features/geofencing/domain/services/attendance_state_machine.dart';
import 'package:time_sheet/services/logger_service.dart';

/// Deux événements identiques séparés de moins de ce délai sont considérés
/// comme un doublon. iOS déclenche notamment le premier événement deux fois
/// après un redémarrage de l'appareil (limitation documentée du plugin).
const Duration _duplicateWindow = Duration(seconds: 10);

/// Point d'entrée appelé par le plugin natif lors d'une entrée ou d'une
/// sortie de zone — y compris lorsque l'application est fermée.
///
/// Ce code s'exécute dans un isolate séparé : ni GetIt, ni BuildContext, ni
/// aucun singleton applicatif n'y est disponible. Toutes les dépendances sont
/// donc instanciées localement et l'état transite par SharedPreferences.
@pragma('vm:entry-point')
Future<void> geofenceCallbackDispatcher(ng.GeofenceCallbackParams params) =>
    handleGeofenceCallback(
      zoneIds: params.geofences.map((g) => g.id).toList(growable: false),
      nativeEvent: params.event,
      at: DateTime.now(),
    );

/// Cœur testable du dispatcher, isolé des types du plugin natif.
Future<void> handleGeofenceCallback({
  required List<String> zoneIds,
  required ng.GeofenceEvent nativeEvent,
  required DateTime at,
  GeofenceNotifier? notifier,
}) async {
  if (zoneIds.isEmpty) return;
  // Le plugin peut regrouper plusieurs zones ; la première suffit, les deux
  // zones de l'application ne se chevauchant pas.
  final zoneId = zoneIds.first;

  final transition = switch (nativeEvent) {
    ng.GeofenceEvent.enter => GeofenceTransition.enter,
    ng.GeofenceEvent.exit => GeofenceTransition.exit,
    // « dwell » n'est pas utilisé : il n'existe pas sur iOS.
    _ => null,
  };
  if (transition == null) return;

  final kind = switch (zoneId) {
    GeofenceService.workZoneId => GeofenceKind.work,
    GeofenceService.homeZoneId => GeofenceKind.home,
    _ => null,
  };
  if (kind == null) {
    logger.w('[Geofencing] Zone inconnue ignorée : $zoneId');
    return;
  }

  final settingsRepository = const GeofenceSettingsRepositoryImpl(
    GeofencePreferencesStore(),
  );
  final runtimeRepository = const GeofenceRuntimeStateRepositoryImpl();
  final mirrorStore = const DayMirrorStore();

  final GeofenceSettings settings;
  try {
    settings = await settingsRepository.load();
  } catch (e) {
    logger.e('[Geofencing] Réglages illisibles depuis l\'isolate : $e');
    return;
  }
  if (!settings.enabled) return;

  var runtime = await runtimeRepository.load();

  // Filtre anti-doublon.
  final previous = runtime.lastEventAt;
  if (previous != null &&
      runtime.lastEventZoneId == zoneId &&
      at.difference(previous).abs() < _duplicateWindow) {
    logger.i('[Geofencing] Événement doublon ignoré sur $zoneId');
    return;
  }
  runtime = runtime.copyWith(lastEventAt: at, lastEventZoneId: zoneId);

  // Une sortie de la zone de travail est mémorisée : elle sert à horodater
  // la pause (à l'heure du départ, pas à l'heure de la détection) et à
  // reconstituer l'heure de sortie le soir.
  if (kind == GeofenceKind.work && transition == GeofenceTransition.exit) {
    runtime = runtime.copyWith(pendingExitAt: at, lastExitAt: at);
  }
  await runtimeRepository.save(runtime);

  var snapshot = await mirrorStore.readForToday(now: at);
  if (snapshot.lastExitAt == null && runtime.lastExitAt != null) {
    snapshot = snapshot.copyWith(lastExitAt: runtime.lastExitAt);
  }

  final decision = const AttendanceStateMachine().decide(
    event: GeofenceEvent(
      zoneId: zoneId,
      kind: kind,
      transition: transition,
      at: at,
    ),
    current: snapshot,
    settings: settings,
    now: at,
  );

  if (decision.action == AttendanceAction.none) {
    logger.i('[Geofencing] Aucune action : ${decision.reason}');
    return;
  }

  // Le miroir est mis à jour tout de suite pour que l'événement suivant
  // raisonne sur un état correct, puis la décision est mise en file : seule
  // l'application au premier plan écrit réellement dans PowerSync.
  await mirrorStore.applyDecision(decision, now: at);
  await mirrorStore.enqueueDecision(decision);

  // Une reprise détectée rend caduque la question de 14 h.
  final geofenceNotifier = notifier ?? GeofenceNotifier();
  await geofenceNotifier.initialize();
  if (decision.action == AttendanceAction.endBreak) {
    await geofenceNotifier.cancelAmbiguity();
  }
  await geofenceNotifier.notifyDecision(decision);

  logger.i('[Geofencing] Décision ${decision.action.name} à '
      '${DayMirrorStore.formatTime(decision.at)} — ${decision.reason}');
}
