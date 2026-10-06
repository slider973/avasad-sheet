import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';
import 'package:time_sheet/features/geofencing/domain/entities/day_pointage_snapshot.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_event.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';

export 'package:time_sheet/features/geofencing/domain/entities/day_pointage_snapshot.dart';

/// Machine à états du pointage automatique.
///
/// Logique métier pure : aucune dépendance Flutter, plugin ou base de données.
/// Elle ne produit que des décisions ; l'application des décisions, la
/// mémorisation de la dernière sortie et l'armement des minuteurs sont du
/// ressort de l'appelant.
class AttendanceStateMachine {
  const AttendanceStateMachine();

  static const String _reasonDisabled = 'Géorepérage désactivé';
  static const String _reasonNothingToDo = 'Aucune action requise';

  AttendanceDecision decide({
    required GeofenceEvent event,
    required DayPointageSnapshot current,
    required GeofenceSettings settings,
    required DateTime now,
  }) {
    if (!settings.enabled) {
      return AttendanceDecision.none(at: event.at, reason: _reasonDisabled);
    }

    if (event.kind == GeofenceKind.work) {
      return event.transition == GeofenceTransition.enter
          ? _onWorkEnter(event, current, settings)
          : _onWorkExit(event, current, settings);
    }

    if (event.kind == GeofenceKind.home &&
        event.transition == GeofenceTransition.enter) {
      return _onHomeEnter(event, current, settings);
    }

    return AttendanceDecision.none(at: event.at, reason: _reasonNothingToDo);
  }

  AttendanceDecision _onWorkEnter(
    GeofenceEvent event,
    DayPointageSnapshot current,
    GeofenceSettings settings,
  ) {
    if (current.startMorning.isEmpty) {
      if (!settings.autoClockIn) {
        return AttendanceDecision.none(
          at: event.at,
          reason: 'Pointage automatique d\'arrivée désactivé',
        );
      }
      return AttendanceDecision(
        action: AttendanceAction.clockIn,
        at: event.at,
        reason: 'Arrivée au travail détectée',
      );
    }

    final isBackFromBreak =
        current.endMorning.isNotEmpty && current.startAfternoon.isEmpty;
    if (isBackFromBreak) {
      if (!settings.autoBreak) {
        return AttendanceDecision.none(
          at: event.at,
          reason: 'Gestion automatique des pauses désactivée',
        );
      }
      return AttendanceDecision(
        action: AttendanceAction.endBreak,
        at: event.at,
        reason: 'Reprise du travail détectée',
      );
    }

    return AttendanceDecision.none(
      at: event.at,
      reason: 'Journée déjà pointée, aucune action',
    );
  }

  AttendanceDecision _onWorkExit(
    GeofenceEvent event,
    DayPointageSnapshot current,
    GeofenceSettings settings,
  ) {
    final isBeforeBreak = current.startMorning.isNotEmpty &&
        current.endMorning.isEmpty;
    if (isBeforeBreak) {
      if (!settings.autoBreak) {
        return AttendanceDecision.none(
          at: event.at,
          reason: 'Gestion automatique des pauses désactivée',
        );
      }
      return AttendanceDecision.none(
        at: event.at,
        reason: 'Sortie de zone, en attente de confirmation de pause',
      );
    }

    final isAfternoonRunning = current.startAfternoon.isNotEmpty &&
        current.endAfternoon.isEmpty;
    if (isAfternoonRunning) {
      return AttendanceDecision.none(
        at: event.at,
        reason: 'Sortie de zone, en attente du retour au domicile',
      );
    }

    return AttendanceDecision.none(at: event.at, reason: _reasonNothingToDo);
  }

  AttendanceDecision _onHomeEnter(
    GeofenceEvent event,
    DayPointageSnapshot current,
    GeofenceSettings settings,
  ) {
    if (!current.isDayStarted || current.isDayClosed) {
      return AttendanceDecision.none(at: event.at, reason: _reasonNothingToDo);
    }

    if (!settings.autoClockOut) {
      return AttendanceDecision.none(
        at: event.at,
        reason: 'Pointage automatique de sortie désactivé',
      );
    }

    final lastExitAt = current.lastExitAt;
    return AttendanceDecision(
      action: AttendanceAction.reconcile,
      at: lastExitAt ?? event.at,
      reason: 'Retour au domicile : pointage de sortie reconstitué',
      needsUserConfirmation: lastExitAt == null,
    );
  }

  /// Évalue une sortie de zone en attente : au-delà du délai minimum, la
  /// sortie devient une vraie pause, horodatée à l'heure de SORTIE.
  AttendanceDecision evaluatePendingBreak({
    required DateTime exitAt,
    required DateTime now,
    required DayPointageSnapshot current,
    required GeofenceSettings settings,
  }) {
    if (!settings.enabled) {
      return AttendanceDecision.none(at: exitAt, reason: _reasonDisabled);
    }

    if (!settings.autoBreak) {
      return AttendanceDecision.none(
        at: exitAt,
        reason: 'Gestion automatique des pauses désactivée',
      );
    }

    if (current.endMorning.isNotEmpty) {
      return AttendanceDecision.none(
        at: exitAt,
        reason: 'Pause déjà pointée',
      );
    }

    final elapsed = now.difference(exitAt);
    if (elapsed < Duration(minutes: settings.breakMinDurationMinutes)) {
      return AttendanceDecision.none(
        at: exitAt,
        reason: 'Absence trop courte pour être une pause',
      );
    }

    return AttendanceDecision(
      action: AttendanceAction.startBreak,
      at: exitAt,
      reason: 'Pause confirmée : absence de zone prolongée',
    );
  }

  /// Contrôle d'ambiguïté : revenu en zone sans avoir repris le travail.
  AttendanceDecision checkAmbiguityAt({
    required DayPointageSnapshot current,
    required GeofenceSettings settings,
    required DateTime now,
  }) {
    if (!settings.enabled) {
      return AttendanceDecision.none(at: now, reason: _reasonDisabled);
    }

    if (!settings.autoBreak) {
      return AttendanceDecision.none(
        at: now,
        reason: 'Gestion automatique des pauses désactivée',
      );
    }

    final threshold = DateTime(
      now.year,
      now.month,
      now.day,
      settings.ambiguityCheckHour,
      settings.ambiguityCheckMinute,
    );
    if (now.isBefore(threshold)) {
      return AttendanceDecision.none(
        at: now,
        reason: 'Contrôle d\'ambiguïté pas encore atteint',
      );
    }

    final isResumeMissing =
        current.endMorning.isNotEmpty && current.startAfternoon.isEmpty;
    if (!isResumeMissing) {
      return AttendanceDecision.none(at: now, reason: _reasonNothingToDo);
    }

    return AttendanceDecision(
      action: AttendanceAction.askAmbiguity,
      at: now,
      reason:
          'Tu es revenu mais tu n\'as pas repris : en pause déjeuner ou au travail ?',
      needsUserConfirmation: true,
    );
  }
}
