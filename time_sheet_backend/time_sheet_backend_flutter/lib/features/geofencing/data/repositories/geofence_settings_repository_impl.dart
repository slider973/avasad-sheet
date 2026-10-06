import 'dart:convert';

import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/repositories/geofence_settings_repository.dart';
import 'package:time_sheet/features/preference/domain/repositories/user_preference_repository.dart';

/// Persiste les réglages de géorepérage sous forme d'un unique document JSON
/// dans les préférences utilisateur.
class GeofenceSettingsRepositoryImpl implements GeofenceSettingsRepository {
  static const String preferenceKey = 'geofencing_settings';

  final UserPreferencesRepository _preferencesRepository;

  const GeofenceSettingsRepositoryImpl(this._preferencesRepository);

  @override
  Future<GeofenceSettings> load() async {
    final raw = await _preferencesRepository.getPreference(preferenceKey);
    if (raw == null || raw.isEmpty) {
      return const GeofenceSettings();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const GeofenceSettings();
      }
      return GeofenceSettings.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      // TODO: journaliser le JSON corrompu avec le logger applicatif.
      return const GeofenceSettings();
    }
  }

  @override
  Future<void> save(GeofenceSettings settings) {
    return _preferencesRepository.setPreference(
      preferenceKey,
      jsonEncode(settings.toJson()),
    );
  }
}
