import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_event.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';
import 'package:time_sheet/features/geofencing/domain/services/attendance_state_machine.dart';

void main() {
  const machine = AttendanceStateMachine();
  const settings = GeofenceSettings(enabled: true);

  DateTime at(int hour, int minute) => DateTime(2026, 10, 6, hour, minute);

  GeofenceEvent workEnter(DateTime moment) => GeofenceEvent(
        zoneId: 'work-1',
        kind: GeofenceKind.work,
        transition: GeofenceTransition.enter,
        at: moment,
      );

  GeofenceEvent workExit(DateTime moment) => GeofenceEvent(
        zoneId: 'work-1',
        kind: GeofenceKind.work,
        transition: GeofenceTransition.exit,
        at: moment,
      );

  GeofenceEvent homeEnter(DateTime moment) => GeofenceEvent(
        zoneId: 'home-1',
        kind: GeofenceKind.home,
        transition: GeofenceTransition.enter,
        at: moment,
      );

  group('Arrivée au travail', () {
    test('arrivée le matin sur une journée vierge déclenche un clockIn', () {
      final event = workEnter(at(8, 2));

      final decision = machine.decide(
        event: event,
        current: const DayPointageSnapshot(),
        settings: settings,
        now: at(8, 2),
      );

      expect(decision.action, AttendanceAction.clockIn);
      expect(decision.at, at(8, 2));
      expect(decision.reason, 'Arrivée au travail détectée');
      expect(decision.needsUserConfirmation, isFalse);
    });

    test('arrivée alors que startMorning est déjà rempli ne pointe pas deux fois',
        () {
      final decision = machine.decide(
        event: workEnter(at(9, 15)),
        current: const DayPointageSnapshot(startMorning: '08:02'),
        settings: settings,
        now: at(9, 15),
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('autoClockIn désactivé empêche le pointage d\'arrivée', () {
      final decision = machine.decide(
        event: workEnter(at(8, 2)),
        current: const DayPointageSnapshot(),
        settings: const GeofenceSettings(enabled: true, autoClockIn: false),
        now: at(8, 2),
      );

      expect(decision.action, AttendanceAction.none);
    });
  });

  group('Sortie de zone et pause', () {
    const morningStarted = DayPointageSnapshot(startMorning: '08:02');

    test('sortie de zone ne décide rien immédiatement', () {
      final decision = machine.decide(
        event: workExit(at(12, 0)),
        current: morningStarted,
        settings: settings,
        now: at(12, 0),
      );

      expect(decision.action, AttendanceAction.none);
      expect(
        decision.reason,
        'Sortie de zone, en attente de confirmation de pause',
      );
    });

    test('sortie courte de 10 minutes ne crée pas de pause', () {
      final decision = machine.evaluatePendingBreak(
        exitAt: at(12, 0),
        now: at(12, 10),
        current: morningStarted,
        settings: settings,
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('sortie longue de 35 minutes crée une pause à l\'heure de SORTIE', () {
      final exitAt = at(12, 0);
      final now = at(12, 35);

      final decision = machine.evaluatePendingBreak(
        exitAt: exitAt,
        now: now,
        current: morningStarted,
        settings: settings,
      );

      expect(decision.action, AttendanceAction.startBreak);
      expect(decision.at, exitAt);
      expect(decision.at, isNot(now),
          reason: 'La pause doit être horodatée à la sortie, pas à maintenant');
    });

    test('pause exactement au seuil des 30 minutes est confirmée', () {
      final decision = machine.evaluatePendingBreak(
        exitAt: at(12, 0),
        now: at(12, 30),
        current: morningStarted,
        settings: settings,
      );

      expect(decision.action, AttendanceAction.startBreak);
    });

    test('pause déjà pointée ne se repointe pas', () {
      final decision = machine.evaluatePendingBreak(
        exitAt: at(12, 0),
        now: at(13, 0),
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
        ),
        settings: settings,
      );

      expect(decision.action, AttendanceAction.none);
    });
  });

  group('Reprise du travail', () {
    test('retour en zone après une pause déclenche endBreak', () {
      final decision = machine.decide(
        event: workEnter(at(13, 5)),
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
        ),
        settings: settings,
        now: at(13, 5),
      );

      expect(decision.action, AttendanceAction.endBreak);
      expect(decision.at, at(13, 5));
      expect(decision.reason, 'Reprise du travail détectée');
    });

    test('reprise déjà pointée ne se repointe pas', () {
      final decision = machine.decide(
        event: workEnter(at(14, 0)),
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
          startAfternoon: '13:05',
        ),
        settings: settings,
        now: at(14, 0),
      );

      expect(decision.action, AttendanceAction.none);
    });
  });

  group('Retour au domicile et réconciliation', () {
    test('arrivée maison sans dépointage reconstitue l\'heure de dernière sortie',
        () {
      final lastExitAt = at(17, 32);

      final decision = machine.decide(
        event: homeEnter(at(18, 10)),
        current: DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
          startAfternoon: '13:05',
          lastExitAt: lastExitAt,
        ),
        settings: settings,
        now: at(18, 10),
      );

      expect(decision.action, AttendanceAction.reconcile);
      expect(decision.at, lastExitAt);
      expect(decision.at, isNot(at(18, 10)));
      expect(decision.needsUserConfirmation, isFalse);
      expect(
        decision.reason,
        'Retour au domicile : pointage de sortie reconstitué',
      );
    });

    test('arrivée maison sans lastExitAt demande confirmation', () {
      final decision = machine.decide(
        event: homeEnter(at(18, 10)),
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
          startAfternoon: '13:05',
        ),
        settings: settings,
        now: at(18, 10),
      );

      expect(decision.action, AttendanceAction.reconcile);
      expect(decision.at, at(18, 10));
      expect(decision.needsUserConfirmation, isTrue);
    });

    test('arrivée maison sans journée commencée ne décide rien', () {
      final decision = machine.decide(
        event: homeEnter(at(18, 10)),
        current: const DayPointageSnapshot(),
        settings: settings,
        now: at(18, 10),
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('arrivée maison alors que la journée est close ne décide rien', () {
      final decision = machine.decide(
        event: homeEnter(at(19, 0)),
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
          startAfternoon: '13:05',
          endAfternoon: '17:32',
        ),
        settings: settings,
        now: at(19, 0),
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('sortie de zone l\'après-midi attend le retour au domicile', () {
      final decision = machine.decide(
        event: workExit(at(17, 32)),
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
          startAfternoon: '13:05',
        ),
        settings: settings,
        now: at(17, 32),
      );

      expect(decision.action, AttendanceAction.none);
    });
  });

  group('Contrôle d\'ambiguïté', () {
    const resumeMissing = DayPointageSnapshot(
      startMorning: '08:02',
      endMorning: '12:00',
    );

    test('à 14 h sans reprise pointée, la question est posée', () {
      final decision = machine.checkAmbiguityAt(
        current: resumeMissing,
        settings: settings,
        now: at(14, 0),
      );

      expect(decision.action, AttendanceAction.askAmbiguity);
      expect(decision.needsUserConfirmation, isTrue);
      expect(
        decision.reason,
        'Tu es revenu mais tu n\'as pas repris : en pause déjeuner ou au travail ?',
      );
    });

    test('à 13 h, il est trop tôt pour poser la question', () {
      final decision = machine.checkAmbiguityAt(
        current: resumeMissing,
        settings: settings,
        now: at(13, 0),
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('à 14 h avec reprise déjà pointée, aucune question', () {
      final decision = machine.checkAmbiguityAt(
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
          startAfternoon: '13:05',
        ),
        settings: settings,
        now: at(14, 0),
      );

      expect(decision.action, AttendanceAction.none);
    });
  });

  group('Réglages désactivés', () {
    const disabled = GeofenceSettings();

    test('géorepérage désactivé : aucune décision sur une arrivée', () {
      final decision = machine.decide(
        event: workEnter(at(8, 2)),
        current: const DayPointageSnapshot(),
        settings: disabled,
        now: at(8, 2),
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('géorepérage désactivé : aucune pause confirmée', () {
      final decision = machine.evaluatePendingBreak(
        exitAt: at(12, 0),
        now: at(13, 0),
        current: const DayPointageSnapshot(startMorning: '08:02'),
        settings: disabled,
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('géorepérage désactivé : aucun contrôle d\'ambiguïté', () {
      final decision = machine.checkAmbiguityAt(
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
        ),
        settings: disabled,
        now: at(14, 0),
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('autoClockOut désactivé : pas de réconciliation au domicile', () {
      final decision = machine.decide(
        event: homeEnter(at(18, 10)),
        current: DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
          startAfternoon: '13:05',
          lastExitAt: at(17, 32),
        ),
        settings: const GeofenceSettings(enabled: true, autoClockOut: false),
        now: at(18, 10),
      );

      expect(decision.action, AttendanceAction.none);
    });

    test('autoBreak désactivé : pas de pause ni de reprise', () {
      const noBreak = GeofenceSettings(enabled: true, autoBreak: false);

      final breakDecision = machine.evaluatePendingBreak(
        exitAt: at(12, 0),
        now: at(13, 0),
        current: const DayPointageSnapshot(startMorning: '08:02'),
        settings: noBreak,
      );
      final resumeDecision = machine.decide(
        event: workEnter(at(13, 5)),
        current: const DayPointageSnapshot(
          startMorning: '08:02',
          endMorning: '12:00',
        ),
        settings: noBreak,
        now: at(13, 5),
      );

      expect(breakDecision.action, AttendanceAction.none);
      expect(resumeDecision.action, AttendanceAction.none);
    });
  });

  group('Sérialisation des réglages', () {
    test('un aller-retour JSON conserve les réglages et les zones', () {
      const original = GeofenceSettings(
        enabled: true,
        autoBreak: false,
        breakMinDurationMinutes: 45,
        ambiguityCheckHour: 13,
        ambiguityCheckMinute: 30,
        workZone: GeofenceZone(
          id: 'work-1',
          label: 'Bureau',
          latitude: 48.8566,
          longitude: 2.3522,
          kind: GeofenceKind.work,
        ),
        homeZone: GeofenceZone(
          id: 'home-1',
          label: 'Maison',
          latitude: 48.85,
          longitude: 2.34,
          radiusMeters: 80,
          kind: GeofenceKind.home,
        ),
      );

      final restored = GeofenceSettings.fromJson(original.toJson());

      expect(restored, original);
      expect(restored.workZone, original.workZone);
      expect(restored.homeZone?.radiusMeters, 80);
    });
  });
}
