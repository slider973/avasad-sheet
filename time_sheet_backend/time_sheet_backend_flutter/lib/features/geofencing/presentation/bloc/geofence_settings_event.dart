import 'package:equatable/equatable.dart';

import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';

/// Événements de l'écran de réglages du pointage automatique.
abstract class GeofenceSettingsEvent extends Equatable {
  const GeofenceSettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Charge les réglages persistés.
class LoadGeofenceSettings extends GeofenceSettingsEvent {
  const LoadGeofenceSettings();
}

/// Active ou désactive globalement le géorepérage.
class ToggleGeofencing extends GeofenceSettingsEvent {
  final bool enabled;

  const ToggleGeofencing(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Active ou désactive le pointage automatique de l'arrivée.
class ToggleAutoClockIn extends GeofenceSettingsEvent {
  final bool enabled;

  const ToggleAutoClockIn(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Active ou désactive la détection automatique des pauses.
class ToggleAutoBreak extends GeofenceSettingsEvent {
  final bool enabled;

  const ToggleAutoBreak(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Active ou désactive le pointage automatique de la sortie.
class ToggleAutoClockOut extends GeofenceSettingsEvent {
  final bool enabled;

  const ToggleAutoClockOut(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

/// Modifie la durée minimale d'absence comptée comme pause.
class UpdateBreakMinDuration extends GeofenceSettingsEvent {
  final int minutes;

  const UpdateBreakMinDuration(this.minutes);

  @override
  List<Object?> get props => [minutes];
}

/// Modifie l'heure du contrôle d'ambiguïté.
class UpdateAmbiguityCheckTime extends GeofenceSettingsEvent {
  final int hour;
  final int minute;

  const UpdateAmbiguityCheckTime(this.hour, this.minute);

  @override
  List<Object?> get props => [hour, minute];
}

/// Définit une zone à partir de la position GPS courante.
class SetZoneFromCurrentPosition extends GeofenceSettingsEvent {
  final GeofenceKind kind;
  final String label;

  const SetZoneFromCurrentPosition(this.kind, this.label);

  @override
  List<Object?> get props => [kind, label];
}

/// Modifie le rayon de détection d'une zone.
class UpdateZoneRadius extends GeofenceSettingsEvent {
  final GeofenceKind kind;
  final double radiusMeters;

  const UpdateZoneRadius(this.kind, this.radiusMeters);

  @override
  List<Object?> get props => [kind, radiusMeters];
}

/// Définit ou remplace les coordonnées d'une zone (saisie manuelle).
class UpdateZoneCoordinates extends GeofenceSettingsEvent {
  final GeofenceKind kind;
  final double latitude;
  final double longitude;
  final String label;

  const UpdateZoneCoordinates(
    this.kind,
    this.latitude,
    this.longitude,
    this.label,
  );

  @override
  List<Object?> get props => [kind, latitude, longitude, label];
}

/// Supprime une zone.
class RemoveZone extends GeofenceSettingsEvent {
  final GeofenceKind kind;

  const RemoveZone(this.kind);

  @override
  List<Object?> get props => [kind];
}
