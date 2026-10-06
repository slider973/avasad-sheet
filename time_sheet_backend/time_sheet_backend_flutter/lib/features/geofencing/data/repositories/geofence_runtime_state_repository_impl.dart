import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_sheet/features/geofencing/domain/services/geofence_runtime_state.dart';
import 'package:time_sheet/services/logger_service.dart';

/// Persiste l'état volatil du géorepérage dans SharedPreferences.
///
/// Cette classe est appelée depuis l'isolate d'arrière-plan du plugin natif,
/// y compris quand l'application est tuée. Elle ne conserve donc AUCUN état en
/// mémoire et ne dépend ni de GetIt ni d'un singleton applicatif : chaque appel
/// relit SharedPreferences via `SharedPreferences.getInstance()`.
class GeofenceRuntimeStateRepositoryImpl
    implements GeofenceRuntimeStateRepository {
  static const String preferenceKey = 'geofencing_runtime_state';

  const GeofenceRuntimeStateRepositoryImpl();

  @override
  Future<GeofenceRuntimeState> load() async {
    final prefs = await SharedPreferences.getInstance();
    // Relecture forcée : un autre isolate (l'app au premier plan) a pu écrire
    // depuis la dernière mise en cache du plugin shared_preferences.
    await prefs.reload();
    final raw = prefs.getString(preferenceKey);
    if (raw == null || raw.isEmpty) {
      return const GeofenceRuntimeState();
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const GeofenceRuntimeState();
      }
      return GeofenceRuntimeState.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException catch (error) {
      logger.w('[geofencing] état volatil corrompu, réinitialisation: $error');
      return const GeofenceRuntimeState();
    }
  }

  @override
  Future<void> save(GeofenceRuntimeState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(preferenceKey, jsonEncode(state.toJson()));
  }
}
