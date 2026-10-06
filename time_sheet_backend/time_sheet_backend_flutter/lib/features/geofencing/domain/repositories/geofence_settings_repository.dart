import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';

/// Accès aux réglages de géorepérage persistés.
abstract class GeofenceSettingsRepository {
  Future<GeofenceSettings> load();

  Future<void> save(GeofenceSettings settings);
}
