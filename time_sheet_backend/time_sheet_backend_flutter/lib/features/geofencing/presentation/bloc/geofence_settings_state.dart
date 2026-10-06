import 'package:equatable/equatable.dart';

import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';

/// Statut de l'écran de réglages du géorepérage.
enum GeofenceSettingsStatus { initial, loading, loaded, saving, error }

/// État de l'écran de réglages du pointage automatique.
class GeofenceSettingsState extends Equatable {
  final GeofenceSettingsStatus status;
  final GeofenceSettings settings;
  final String? errorMessage;

  /// Vrai pendant l'acquisition de la position GPS.
  final bool isLocating;

  const GeofenceSettingsState({
    this.status = GeofenceSettingsStatus.initial,
    this.settings = const GeofenceSettings(),
    this.errorMessage,
    this.isLocating = false,
  });

  GeofenceSettingsState copyWith({
    GeofenceSettingsStatus? status,
    GeofenceSettings? settings,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isLocating,
  }) {
    return GeofenceSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isLocating: isLocating ?? this.isLocating,
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage, isLocating];
}
