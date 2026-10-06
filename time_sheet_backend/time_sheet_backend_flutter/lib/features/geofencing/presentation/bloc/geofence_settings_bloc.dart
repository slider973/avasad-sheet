import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';
import 'package:time_sheet/features/geofencing/domain/repositories/geofence_settings_repository.dart';
import 'package:time_sheet/features/geofencing/presentation/bloc/geofence_settings_event.dart';
import 'package:time_sheet/features/geofencing/presentation/bloc/geofence_settings_state.dart';
import 'package:time_sheet/services/logger_service.dart';

/// Gère les réglages du pointage automatique par géorepérage.
///
/// Toutes les dépendances sont injectées par le constructeur afin de rester
/// testable sans conteneur d'injection.
class GeofenceSettingsBloc
    extends Bloc<GeofenceSettingsEvent, GeofenceSettingsState> {
  final GeofenceSettingsRepository repository;

  /// Hook appelé après chaque sauvegarde réussie.
  /// Le parent y branche la re-synchronisation des zones natives.
  final Future<void> Function(GeofenceSettings settings)? onSettingsChanged;

  GeofenceSettingsBloc({
    required this.repository,
    this.onSettingsChanged,
  }) : super(const GeofenceSettingsState()) {
    on<LoadGeofenceSettings>(_onLoad);
    on<ToggleGeofencing>(_onToggleGeofencing);
    on<ToggleAutoClockIn>(_onToggleAutoClockIn);
    on<ToggleAutoBreak>(_onToggleAutoBreak);
    on<ToggleAutoClockOut>(_onToggleAutoClockOut);
    on<UpdateBreakMinDuration>(_onUpdateBreakMinDuration);
    on<UpdateAmbiguityCheckTime>(_onUpdateAmbiguityCheckTime);
    on<SetZoneFromCurrentPosition>(_onSetZoneFromCurrentPosition);
    on<UpdateZoneRadius>(_onUpdateZoneRadius);
    on<UpdateZoneCoordinates>(_onUpdateZoneCoordinates);
    on<RemoveZone>(_onRemoveZone);
  }

  Future<void> _onLoad(
    LoadGeofenceSettings event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: GeofenceSettingsStatus.loading,
      clearErrorMessage: true,
    ));
    try {
      final settings = await repository.load();
      emit(state.copyWith(
        status: GeofenceSettingsStatus.loaded,
        settings: settings,
        clearErrorMessage: true,
      ));
    } catch (error, stackTrace) {
      logger.e('Chargement des réglages de géorepérage impossible',
          error: error, stackTrace: stackTrace);
      emit(state.copyWith(
        status: GeofenceSettingsStatus.error,
        errorMessage: 'Impossible de charger les réglages.',
      ));
    }
  }

  /// Persiste les réglages et notifie le parent.
  Future<void> _persist(
    GeofenceSettings settings,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    emit(state.copyWith(
      status: GeofenceSettingsStatus.saving,
      settings: settings,
      clearErrorMessage: true,
    ));
    try {
      await repository.save(settings);
      if (onSettingsChanged != null) {
        await onSettingsChanged!(settings);
      }
      emit(state.copyWith(
        status: GeofenceSettingsStatus.loaded,
        settings: settings,
        clearErrorMessage: true,
      ));
    } catch (error, stackTrace) {
      logger.e('Sauvegarde des réglages de géorepérage impossible',
          error: error, stackTrace: stackTrace);
      emit(state.copyWith(
        status: GeofenceSettingsStatus.error,
        errorMessage: 'Impossible d\'enregistrer les réglages.',
      ));
    }
  }

  Future<void> _onToggleGeofencing(
    ToggleGeofencing event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    await _persist(state.settings.copyWith(enabled: event.enabled), emit);
  }

  Future<void> _onToggleAutoClockIn(
    ToggleAutoClockIn event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    await _persist(state.settings.copyWith(autoClockIn: event.enabled), emit);
  }

  Future<void> _onToggleAutoBreak(
    ToggleAutoBreak event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    await _persist(state.settings.copyWith(autoBreak: event.enabled), emit);
  }

  Future<void> _onToggleAutoClockOut(
    ToggleAutoClockOut event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    await _persist(state.settings.copyWith(autoClockOut: event.enabled), emit);
  }

  Future<void> _onUpdateBreakMinDuration(
    UpdateBreakMinDuration event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    await _persist(
      state.settings.copyWith(breakMinDurationMinutes: event.minutes),
      emit,
    );
  }

  Future<void> _onUpdateAmbiguityCheckTime(
    UpdateAmbiguityCheckTime event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    await _persist(
      state.settings.copyWith(
        ambiguityCheckHour: event.hour,
        ambiguityCheckMinute: event.minute,
      ),
      emit,
    );
  }

  Future<void> _onUpdateZoneRadius(
    UpdateZoneRadius event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    final zone = _zoneOf(state.settings, event.kind);
    if (zone == null) return;
    await _persist(
      _withZone(
        state.settings,
        event.kind,
        zone.copyWith(radiusMeters: event.radiusMeters),
      ),
      emit,
    );
  }

  Future<void> _onUpdateZoneCoordinates(
    UpdateZoneCoordinates event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    final existing = _zoneOf(state.settings, event.kind);
    final zone = GeofenceZone(
      id: existing?.id ?? _zoneId(event.kind),
      label: event.label,
      latitude: event.latitude,
      longitude: event.longitude,
      radiusMeters: existing?.radiusMeters ?? 150,
      kind: event.kind,
    );
    await _persist(_withZone(state.settings, event.kind, zone), emit);
  }

  Future<void> _onRemoveZone(
    RemoveZone event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    final settings = event.kind == GeofenceKind.work
        ? state.settings.copyWith(clearWorkZone: true)
        : state.settings.copyWith(clearHomeZone: true);
    await _persist(settings, emit);
  }

  Future<void> _onSetZoneFromCurrentPosition(
    SetZoneFromCurrentPosition event,
    Emitter<GeofenceSettingsState> emit,
  ) async {
    emit(state.copyWith(isLocating: true, clearErrorMessage: true));
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(state.copyWith(
          status: GeofenceSettingsStatus.error,
          isLocating: false,
          errorMessage:
              'Le service de localisation est désactivé sur cet appareil.',
        ));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          status: GeofenceSettingsStatus.error,
          isLocating: false,
          errorMessage: 'Autorisation de localisation refusée',
        ));
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      final existing = _zoneOf(state.settings, event.kind);
      final zone = GeofenceZone(
        id: existing?.id ?? _zoneId(event.kind),
        label: event.label,
        latitude: position.latitude,
        longitude: position.longitude,
        radiusMeters: existing?.radiusMeters ?? 150,
        kind: event.kind,
      );
      emit(state.copyWith(isLocating: false));
      await _persist(_withZone(state.settings, event.kind, zone), emit);
    } catch (error, stackTrace) {
      logger.e('Acquisition de la position courante impossible',
          error: error, stackTrace: stackTrace);
      emit(state.copyWith(
        status: GeofenceSettingsStatus.error,
        isLocating: false,
        errorMessage: 'Impossible de récupérer votre position actuelle.',
      ));
    }
  }

  GeofenceZone? _zoneOf(GeofenceSettings settings, GeofenceKind kind) {
    return kind == GeofenceKind.work ? settings.workZone : settings.homeZone;
  }

  GeofenceSettings _withZone(
    GeofenceSettings settings,
    GeofenceKind kind,
    GeofenceZone zone,
  ) {
    return kind == GeofenceKind.work
        ? settings.copyWith(workZone: zone)
        : settings.copyWith(homeZone: zone);
  }

  String _zoneId(GeofenceKind kind) =>
      kind == GeofenceKind.work ? 'work_zone' : 'home_zone';
}
