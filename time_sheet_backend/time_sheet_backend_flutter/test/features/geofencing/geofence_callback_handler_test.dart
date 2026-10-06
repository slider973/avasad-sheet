import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:native_geofence/native_geofence.dart' as ng;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/features/geofencing/data/repositories/geofence_preferences_store.dart';
import 'package:time_sheet/features/geofencing/data/repositories/geofence_settings_repository_impl.dart';
import 'package:time_sheet/features/geofencing/data/services/day_mirror_store.dart';
import 'package:time_sheet/features/geofencing/data/services/geofence_callback_handler.dart';
import 'package:time_sheet/features/geofencing/data/services/geofence_notifier.dart';
import 'package:time_sheet/features/geofencing/data/services/geofence_service.dart';
import 'package:time_sheet/features/geofencing/domain/entities/attendance_decision.dart';
import 'package:time_sheet/features/geofencing/domain/entities/day_pointage_snapshot.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';

/// Notificateur muet : les notifications locales ne sont pas testables sans
/// device, seules les décisions nous intéressent ici.
class _SilentNotifier extends GeofenceNotifier {
  final List<AttendanceDecision> notified = [];
  int ambiguityCancelled = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> notifyDecision(AttendanceDecision decision) async {
    notified.add(decision);
  }

  @override
  Future<void> cancelAmbiguity() async {
    ambiguityCancelled++;
  }
}

GeofenceSettings _settingsAvecZones() => GeofenceSettings(
      enabled: true,
      workZone: const GeofenceZone(
        id: GeofenceService.workZoneId,
        label: 'Bureau',
        latitude: 46.5197,
        longitude: 6.6323,
        kind: GeofenceKind.work,
      ),
      homeZone: const GeofenceZone(
        id: GeofenceService.homeZoneId,
        label: 'Domicile',
        latitude: 46.4628,
        longitude: 6.8419,
        kind: GeofenceKind.home,
      ),
    );

Future<void> _ecrireReglages(GeofenceSettings settings) async {
  await const GeofenceSettingsRepositoryImpl(GeofencePreferencesStore())
      .save(settings);
}

Future<Map<String, dynamic>?> _lireMiroir() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final raw = prefs.getString(DayMirrorStore.mirrorKey);
  return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Miroir du pointage du jour', () {
    test('un miroir absent donne une journée vierge', () async {
      final snapshot = await const DayMirrorStore().readForToday();
      expect(snapshot.startMorning, isEmpty);
      expect(snapshot.endAfternoon, isEmpty);
    });

    test('le miroir de la veille est ignoré', () async {
      const store = DayMirrorStore();
      final hier = DateTime(2026, 10, 5, 8, 30);
      await store.write(
        const DayPointageSnapshot(startMorning: '08:30'),
        hier,
      );

      final aujourdhui = await store.readForToday(
        now: DateTime(2026, 10, 6, 8, 0),
      );
      expect(aujourdhui.startMorning, isEmpty,
          reason: 'les créneaux de la veille ne doivent jamais être repris');
    });

    test('appliquer une décision met à jour le bon créneau', () async {
      const store = DayMirrorStore();
      final jour = DateTime(2026, 10, 6, 8, 32);

      await store.applyDecision(
        AttendanceDecision(
          action: AttendanceAction.clockIn,
          at: jour,
          reason: 'test',
        ),
        now: jour,
      );
      var miroir = await _lireMiroir();
      expect(miroir!['startMorning'], '08:32');

      await store.applyDecision(
        AttendanceDecision(
          action: AttendanceAction.startBreak,
          at: DateTime(2026, 10, 6, 12, 5),
          reason: 'test',
        ),
        now: jour,
      );
      miroir = await _lireMiroir();
      expect(miroir!['endMorning'], '12:05');
      expect(miroir['startMorning'], '08:32',
          reason: 'les créneaux déjà remplis ne doivent pas être écrasés');
    });

    test('la file de décisions se vide à la lecture', () async {
      const store = DayMirrorStore();
      await store.enqueueDecision(AttendanceDecision(
        action: AttendanceAction.clockIn,
        at: DateTime(2026, 10, 6, 8, 32),
        reason: 'arrivée',
      ));

      final premier = await store.drainPendingDecisions();
      expect(premier, hasLength(1));
      expect(premier.first.action, AttendanceAction.clockIn);

      final second = await store.drainPendingDecisions();
      expect(second, isEmpty, reason: 'une décision ne doit être rejouée');
    });
  });

  group('Dispatcher des événements de zone', () {
    test('arrivée au travail enfile un pointage et notifie', () async {
      await _ecrireReglages(_settingsAvecZones());
      final notifier = _SilentNotifier();
      final arrivee = DateTime(2026, 10, 6, 8, 32);

      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.workZoneId],
        nativeEvent: ng.GeofenceEvent.enter,
        at: arrivee,
        notifier: notifier,
      );

      expect(notifier.notified, hasLength(1));
      expect(notifier.notified.first.action, AttendanceAction.clockIn);

      final file = await const DayMirrorStore().drainPendingDecisions();
      expect(file, hasLength(1));
      expect(file.first.at, arrivee);
    });

    test('un événement doublon à 3 secondes est ignoré', () async {
      await _ecrireReglages(_settingsAvecZones());
      final notifier = _SilentNotifier();
      final premier = DateTime(2026, 10, 6, 8, 32);

      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.workZoneId],
        nativeEvent: ng.GeofenceEvent.enter,
        at: premier,
        notifier: notifier,
      );
      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.workZoneId],
        nativeEvent: ng.GeofenceEvent.enter,
        at: premier.add(const Duration(seconds: 3)),
        notifier: notifier,
      );

      expect(notifier.notified, hasLength(1),
          reason: 'iOS déclenche deux fois le premier événement au reboot');
    });

    test('géorepérage désactivé : aucune décision', () async {
      await _ecrireReglages(
        _settingsAvecZones().copyWith(enabled: false),
      );
      final notifier = _SilentNotifier();

      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.workZoneId],
        nativeEvent: ng.GeofenceEvent.enter,
        at: DateTime(2026, 10, 6, 8, 32),
        notifier: notifier,
      );

      expect(notifier.notified, isEmpty);
    });

    test('zone inconnue ignorée sans effet', () async {
      await _ecrireReglages(_settingsAvecZones());
      final notifier = _SilentNotifier();

      await handleGeofenceCallback(
        zoneIds: const ['zone_inattendue'],
        nativeEvent: ng.GeofenceEvent.enter,
        at: DateTime(2026, 10, 6, 8, 32),
        notifier: notifier,
      );

      expect(notifier.notified, isEmpty);
    });

    test('sortie du travail mémorise l\'heure sans rien pointer', () async {
      await _ecrireReglages(_settingsAvecZones());
      final notifier = _SilentNotifier();
      final jour = DateTime(2026, 10, 6, 8, 32);

      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.workZoneId],
        nativeEvent: ng.GeofenceEvent.enter,
        at: jour,
        notifier: notifier,
      );
      await const DayMirrorStore().drainPendingDecisions();
      notifier.notified.clear();

      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.workZoneId],
        nativeEvent: ng.GeofenceEvent.exit,
        at: DateTime(2026, 10, 6, 12, 5),
        notifier: notifier,
      );

      expect(notifier.notified, isEmpty,
          reason: 'une sortie seule n\'est pas une pause : on attend 30 min');
    });

    test('retour au domicile reconstitue la sortie à l\'heure du départ',
        () async {
      await _ecrireReglages(_settingsAvecZones());
      final notifier = _SilentNotifier();

      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.workZoneId],
        nativeEvent: ng.GeofenceEvent.enter,
        at: DateTime(2026, 10, 6, 8, 32),
        notifier: notifier,
      );
      final depart = DateTime(2026, 10, 6, 17, 48);
      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.workZoneId],
        nativeEvent: ng.GeofenceEvent.exit,
        at: depart,
        notifier: notifier,
      );
      await const DayMirrorStore().drainPendingDecisions();
      notifier.notified.clear();

      await handleGeofenceCallback(
        zoneIds: const [GeofenceService.homeZoneId],
        nativeEvent: ng.GeofenceEvent.enter,
        at: DateTime(2026, 10, 6, 18, 25),
        notifier: notifier,
      );

      expect(notifier.notified, hasLength(1));
      final decision = notifier.notified.first;
      expect(decision.action, AttendanceAction.reconcile);
      expect(decision.at, depart,
          reason: 'l\'heure retenue est le départ du travail (17:48), '
              'pas l\'arrivée à la maison (18:25)');
    });
  });
}
