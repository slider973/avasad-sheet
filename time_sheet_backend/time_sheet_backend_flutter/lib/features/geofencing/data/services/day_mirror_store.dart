import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';
import 'package:time_sheet/features/geofencing/domain/entities/day_pointage_snapshot.dart';

/// Miroir léger du pointage du jour, lisible depuis l'isolate d'arrière-plan.
///
/// L'isolate déclenché par le plugin natif ne peut pas ouvrir PowerSync de
/// façon fiable : la base est déjà verrouillée par l'application et le moteur
/// de synchronisation n'est pas initialisé. On maintient donc une copie
/// minimale des quatre créneaux du jour dans SharedPreferences, écrite par
/// l'application au premier plan et relue par l'isolate.
///
/// Ce miroir n'est jamais la source de vérité : il sert à décider, pas à
/// stocker. L'écriture réelle se fait au prochain démarrage de l'application,
/// en rejouant la file d'attente des décisions.
class DayMirrorStore {
  static const String mirrorKey = 'geofencing_day_mirror';
  static const String pendingDecisionsKey = 'geofencing_pending_decisions';

  const DayMirrorStore();

  String _dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// Lit le miroir du jour. Renvoie un instantané vierge si le miroir est
  /// absent ou s'il date d'un autre jour (changement de journée pendant la
  /// nuit : on ne reporte jamais les créneaux de la veille).
  Future<DayPointageSnapshot> readForToday({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final raw = prefs.getString(mirrorKey);
    if (raw == null || raw.isEmpty) return const DayPointageSnapshot();

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['date'] != _dayKey(today)) return const DayPointageSnapshot();
      final lastExitRaw = map['lastExitAt'] as String?;
      return DayPointageSnapshot(
        startMorning: (map['startMorning'] as String?) ?? '',
        endMorning: (map['endMorning'] as String?) ?? '',
        startAfternoon: (map['startAfternoon'] as String?) ?? '',
        endAfternoon: (map['endAfternoon'] as String?) ?? '',
        lastExitAt:
            lastExitRaw == null ? null : DateTime.tryParse(lastExitRaw),
      );
    } catch (_) {
      // Miroir corrompu : on repart d'une journée vierge plutôt que de
      // propager une exception dans l'isolate d'arrière-plan.
      return const DayPointageSnapshot();
    }
  }

  Future<void> write(DayPointageSnapshot snapshot, DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      mirrorKey,
      jsonEncode({
        'date': _dayKey(day),
        'startMorning': snapshot.startMorning,
        'endMorning': snapshot.endMorning,
        'startAfternoon': snapshot.startAfternoon,
        'endAfternoon': snapshot.endAfternoon,
        'lastExitAt': snapshot.lastExitAt?.toIso8601String(),
      }),
    );
  }

  static String formatTime(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';

  /// Applique une décision au miroir local pour que l'événement suivant
  /// raisonne sur un état à jour, sans attendre l'écriture en base.
  Future<DayPointageSnapshot> applyDecision(
    AttendanceDecision decision, {
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final current = await readForToday(now: today);
    final stamp = formatTime(decision.at);

    final updated = switch (decision.action) {
      AttendanceAction.clockIn => current.copyWith(startMorning: stamp),
      AttendanceAction.startBreak => current.copyWith(endMorning: stamp),
      AttendanceAction.endBreak => current.copyWith(startAfternoon: stamp),
      AttendanceAction.clockOut ||
      AttendanceAction.reconcile =>
        current.copyWith(endAfternoon: stamp),
      _ => current,
    };

    if (!identical(updated, current)) await write(updated, today);
    return updated;
  }

  /// Enfile une décision pour que l'application l'écrive réellement dans
  /// PowerSync à son prochain démarrage.
  Future<void> enqueueDecision(AttendanceDecision decision) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final queue = prefs.getStringList(pendingDecisionsKey) ?? <String>[];
    queue.add(jsonEncode({
      'action': decision.action.name,
      'at': decision.at.toIso8601String(),
      'reason': decision.reason,
      'needsUserConfirmation': decision.needsUserConfirmation,
    }));
    await prefs.setStringList(pendingDecisionsKey, queue);
  }

  /// Retire et renvoie les décisions en attente (consommées une seule fois).
  Future<List<AttendanceDecision>> drainPendingDecisions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final queue = prefs.getStringList(pendingDecisionsKey) ?? <String>[];
    if (queue.isEmpty) return const <AttendanceDecision>[];
    await prefs.remove(pendingDecisionsKey);

    final decisions = <AttendanceDecision>[];
    for (final raw in queue) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final action = AttendanceAction.values.firstWhere(
          (a) => a.name == map['action'],
          orElse: () => AttendanceAction.none,
        );
        if (action == AttendanceAction.none) continue;
        decisions.add(AttendanceDecision(
          action: action,
          at: DateTime.parse(map['at'] as String),
          reason: (map['reason'] as String?) ?? '',
          needsUserConfirmation:
              (map['needsUserConfirmation'] as bool?) ?? false,
        ));
      } catch (_) {
        // Entrée illisible ignorée : mieux vaut perdre une décision que
        // bloquer la reprise de toute la file.
        continue;
      }
    }
    return decisions;
  }
}
