import 'package:flutter_test/flutter_test.dart';

import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';
import 'package:time_sheet/features/geofencing/domain/repositories/geofence_settings_repository.dart';
import 'package:time_sheet/features/geofencing/presentation/bloc/geofence_settings_bloc.dart';
import 'package:time_sheet/features/geofencing/presentation/bloc/geofence_settings_event.dart';
import 'package:time_sheet/features/geofencing/presentation/bloc/geofence_settings_state.dart';

/// Faux repository en mémoire (le projet n'utilise ni bloc_test ni mocktail).
class _FakeGeofenceSettingsRepository implements GeofenceSettingsRepository {
  GeofenceSettings stored;
  final List<GeofenceSettings> savedCalls = [];

  _FakeGeofenceSettingsRepository([GeofenceSettings? initial])
      : stored = initial ?? const GeofenceSettings();

  @override
  Future<GeofenceSettings> load() async => stored;

  @override
  Future<void> save(GeofenceSettings settings) async {
    stored = settings;
    savedCalls.add(settings);
  }
}

void main() {
  const workZone = GeofenceZone(
    id: 'work_zone',
    label: 'Lieu de travail',
    latitude: 48.8566,
    longitude: 2.3522,
    radiusMeters: 150,
    kind: GeofenceKind.work,
  );

  const homeZone = GeofenceZone(
    id: 'home_zone',
    label: 'Domicile',
    latitude: 48.85,
    longitude: 2.34,
    radiusMeters: 120,
    kind: GeofenceKind.home,
  );

  /// Attend que le bloc ait atteint l'état « loaded » (fin de sauvegarde).
  Future<void> waitSettled(GeofenceSettingsBloc bloc) async {
    await bloc.stream.firstWhere(
      (state) =>
          state.status == GeofenceSettingsStatus.loaded ||
          state.status == GeofenceSettingsStatus.error,
    );
  }

  group('GeofenceSettingsBloc', () {
    test('état initial', () {
      final repository = _FakeGeofenceSettingsRepository();
      final bloc = GeofenceSettingsBloc(repository: repository);

      expect(bloc.state.status, GeofenceSettingsStatus.initial);
      expect(bloc.state.settings, const GeofenceSettings());
      expect(bloc.state.isLocating, isFalse);
      expect(bloc.state.errorMessage, isNull);

      bloc.close();
    });

    test('LoadGeofenceSettings charge les réglages persistés', () async {
      final repository = _FakeGeofenceSettingsRepository(
        const GeofenceSettings(
          enabled: true,
          breakMinDurationMinutes: 45,
          ambiguityCheckHour: 13,
          ambiguityCheckMinute: 30,
          workZone: workZone,
        ),
      );
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      expect(bloc.state.status, GeofenceSettingsStatus.loaded);
      expect(bloc.state.settings.enabled, isTrue);
      expect(bloc.state.settings.breakMinDurationMinutes, 45);
      expect(bloc.state.settings.ambiguityCheckHour, 13);
      expect(bloc.state.settings.workZone, workZone);

      await bloc.close();
    });

    test('LoadGeofenceSettings émet une erreur si le repository échoue',
        () async {
      final bloc = GeofenceSettingsBloc(repository: _ThrowingRepository());

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      expect(bloc.state.status, GeofenceSettingsStatus.error);
      expect(bloc.state.errorMessage, isNotNull);

      await bloc.close();
    });

    test('ToggleGeofencing active et persiste le géorepérage', () async {
      final repository = _FakeGeofenceSettingsRepository();
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const ToggleGeofencing(true));
      await waitSettled(bloc);

      expect(bloc.state.settings.enabled, isTrue);
      expect(repository.stored.enabled, isTrue);
      expect(repository.savedCalls, hasLength(1));

      await bloc.close();
    });

    test('ToggleGeofencing désactive et persiste le géorepérage', () async {
      final repository = _FakeGeofenceSettingsRepository(
        const GeofenceSettings(enabled: true),
      );
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const ToggleGeofencing(false));
      await waitSettled(bloc);

      expect(bloc.state.settings.enabled, isFalse);
      expect(repository.stored.enabled, isFalse);

      await bloc.close();
    });

    test('les trois automatismes sont persistés', () async {
      final repository = _FakeGeofenceSettingsRepository();
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const ToggleAutoClockIn(false));
      await waitSettled(bloc);
      bloc.add(const ToggleAutoBreak(false));
      await waitSettled(bloc);
      bloc.add(const ToggleAutoClockOut(false));
      await waitSettled(bloc);

      expect(repository.stored.autoClockIn, isFalse);
      expect(repository.stored.autoBreak, isFalse);
      expect(repository.stored.autoClockOut, isFalse);

      await bloc.close();
    });

    test('UpdateZoneRadius met à jour le rayon de la zone travail', () async {
      final repository = _FakeGeofenceSettingsRepository(
        const GeofenceSettings(enabled: true, workZone: workZone),
      );
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const UpdateZoneRadius(GeofenceKind.work, 320));
      await waitSettled(bloc);

      expect(bloc.state.settings.workZone?.radiusMeters, 320);
      expect(repository.stored.workZone?.radiusMeters, 320);
      // Les autres champs de la zone sont préservés.
      expect(repository.stored.workZone?.latitude, workZone.latitude);

      await bloc.close();
    });

    test('UpdateZoneRadius sans zone définie ne sauvegarde rien', () async {
      final repository = _FakeGeofenceSettingsRepository();
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const UpdateZoneRadius(GeofenceKind.work, 320));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.savedCalls, isEmpty);

      await bloc.close();
    });

    test('UpdateZoneCoordinates crée la zone domicile', () async {
      final repository = _FakeGeofenceSettingsRepository();
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const UpdateZoneCoordinates(
          GeofenceKind.home, 48.85, 2.34, 'Domicile'));
      await waitSettled(bloc);

      final zone = repository.stored.homeZone;
      expect(zone, isNotNull);
      expect(zone!.kind, GeofenceKind.home);
      expect(zone.latitude, 48.85);
      expect(zone.longitude, 2.34);
      expect(zone.label, 'Domicile');
      expect(zone.radiusMeters, 150);

      await bloc.close();
    });

    test('UpdateBreakMinDuration persiste la durée de pause', () async {
      final repository = _FakeGeofenceSettingsRepository();
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const UpdateBreakMinDuration(15));
      await waitSettled(bloc);

      expect(bloc.state.settings.breakMinDurationMinutes, 15);
      expect(repository.stored.breakMinDurationMinutes, 15);

      await bloc.close();
    });

    test('UpdateAmbiguityCheckTime persiste l\'heure de contrôle', () async {
      final repository = _FakeGeofenceSettingsRepository();
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const UpdateAmbiguityCheckTime(13, 45));
      await waitSettled(bloc);

      expect(repository.stored.ambiguityCheckHour, 13);
      expect(repository.stored.ambiguityCheckMinute, 45);

      await bloc.close();
    });

    test('RemoveZone supprime la zone travail sans toucher au domicile',
        () async {
      final repository = _FakeGeofenceSettingsRepository(
        const GeofenceSettings(
          enabled: true,
          workZone: workZone,
          homeZone: homeZone,
        ),
      );
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const RemoveZone(GeofenceKind.work));
      await waitSettled(bloc);

      expect(bloc.state.settings.workZone, isNull);
      expect(repository.stored.workZone, isNull);
      expect(repository.stored.homeZone, homeZone);

      await bloc.close();
    });

    test('RemoveZone supprime la zone domicile', () async {
      final repository = _FakeGeofenceSettingsRepository(
        const GeofenceSettings(
          enabled: true,
          workZone: workZone,
          homeZone: homeZone,
        ),
      );
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const RemoveZone(GeofenceKind.home));
      await waitSettled(bloc);

      expect(repository.stored.homeZone, isNull);
      expect(repository.stored.workZone, workZone);

      await bloc.close();
    });

    test('onSettingsChanged est appelé après chaque sauvegarde', () async {
      final repository = _FakeGeofenceSettingsRepository();
      final notified = <GeofenceSettings>[];
      final bloc = GeofenceSettingsBloc(
        repository: repository,
        onSettingsChanged: (settings) async => notified.add(settings),
      );

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);
      // Le chargement ne déclenche pas le hook.
      expect(notified, isEmpty);

      bloc.add(const ToggleGeofencing(true));
      await waitSettled(bloc);
      bloc.add(const UpdateBreakMinDuration(20));
      await waitSettled(bloc);

      expect(notified, hasLength(2));
      expect(notified.first.enabled, isTrue);
      expect(notified.last.breakMinDurationMinutes, 20);

      await bloc.close();
    });

    test('un hook null n\'empêche pas la sauvegarde', () async {
      final repository = _FakeGeofenceSettingsRepository();
      final bloc = GeofenceSettingsBloc(repository: repository);

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const ToggleGeofencing(true));
      await waitSettled(bloc);

      expect(bloc.state.status, GeofenceSettingsStatus.loaded);
      expect(repository.stored.enabled, isTrue);

      await bloc.close();
    });

    test('une erreur de sauvegarde produit le statut error', () async {
      final bloc = GeofenceSettingsBloc(repository: _ThrowingRepository(
        failOnLoad: false,
      ));

      bloc.add(const LoadGeofenceSettings());
      await waitSettled(bloc);

      bloc.add(const ToggleGeofencing(true));
      await waitSettled(bloc);

      expect(bloc.state.status, GeofenceSettingsStatus.error);
      expect(bloc.state.errorMessage, isNotNull);

      await bloc.close();
    });
  });
}

/// Repository qui échoue, pour couvrir les chemins d'erreur.
class _ThrowingRepository implements GeofenceSettingsRepository {
  final bool failOnLoad;

  _ThrowingRepository({this.failOnLoad = true});

  @override
  Future<GeofenceSettings> load() async {
    if (failOnLoad) throw Exception('boom');
    return const GeofenceSettings();
  }

  @override
  Future<void> save(GeofenceSettings settings) async {
    throw Exception('boom');
  }
}
