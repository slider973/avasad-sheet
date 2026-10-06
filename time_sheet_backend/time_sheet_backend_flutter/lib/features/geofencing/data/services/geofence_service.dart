import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart' as ng;
import 'package:time_sheet/features/geofencing/data/services/geofence_callback_handler.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_settings.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';
import 'package:time_sheet/services/logger_service.dart';

/// Pilote le plugin natif de géorepérage : permissions et synchronisation des
/// zones surveillées avec les réglages de l'utilisateur.
class GeofenceService {
  static const String workZoneId = 'timesheet_work';
  static const String homeZoneId = 'timesheet_home';

  const GeofenceService();

  Future<void> initialize() async {
    await ng.NativeGeofenceManager.instance.initialize();
    logger.i('[Geofencing] Plugin natif initialisé');
  }

  /// Demande la localisation « Toujours », indispensable pour détecter les
  /// entrées et sorties de zone quand l'application est fermée.
  ///
  /// Sur iOS, le système accorde rarement « Toujours » du premier coup : il
  /// commence par « Lorsque l'app est active » puis propose lui-même de
  /// passer à « Toujours » après quelques déclenchements. Un retour `false`
  /// n'est donc pas définitif ; l'écran de réglages doit rester utilisable.
  Future<bool> requestPermissions() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      logger.w('[Geofencing] Service de localisation désactivé');
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      logger.w('[Geofencing] Localisation refusée définitivement');
      return false;
    }
    if (permission == LocationPermission.whileInUse) {
      // Deuxième demande : sur Android 11+ elle ouvre les réglages système.
      permission = await Geolocator.requestPermission();
    }

    final granted = permission == LocationPermission.always;
    logger.i('[Geofencing] Permission accordée : ${permission.name}');
    return granted;
  }

  ng.Geofence _toNativeGeofence(GeofenceZone zone, String id) => ng.Geofence(
        id: id,
        location: ng.Location(
          latitude: zone.latitude,
          longitude: zone.longitude,
        ),
        radiusMeters: zone.radiusMeters,
        triggers: const {ng.GeofenceEvent.enter, ng.GeofenceEvent.exit},
        iosSettings: const ng.IosGeofenceSettings(initialTrigger: true),
        androidSettings: const ng.AndroidGeofenceSettings(
          initialTriggers: {ng.GeofenceEvent.enter},
          loiteringDelay: Duration(minutes: 1),
        ),
      );

  /// Aligne les zones surveillées sur les réglages. Idempotent : ne touche
  /// qu'aux zones réellement différentes de ce qui est déjà enregistré.
  Future<void> syncZones(GeofenceSettings settings) async {
    final registered = await ng.NativeGeofenceManager.instance
        .getRegisteredGeofences();
    final registeredById = {for (final g in registered) g.id: g};

    if (!settings.enabled) {
      if (registered.isNotEmpty) {
        await ng.NativeGeofenceManager.instance.removeAllGeofences();
        logger.i('[Geofencing] Géorepérage désactivé : zones supprimées');
      }
      return;
    }

    final wanted = <String, GeofenceZone>{
      if (settings.workZone != null) workZoneId: settings.workZone!,
      if (settings.homeZone != null) homeZoneId: settings.homeZone!,
    };

    for (final id in registeredById.keys) {
      if (!wanted.containsKey(id)) {
        await ng.NativeGeofenceManager.instance.removeGeofenceById(id);
        logger.i('[Geofencing] Zone retirée : $id');
      }
    }

    for (final entry in wanted.entries) {
      final existing = registeredById[entry.key];
      final zone = entry.value;
      final unchanged = existing != null &&
          existing.location.latitude == zone.latitude &&
          existing.location.longitude == zone.longitude &&
          existing.radiusMeters == zone.radiusMeters;
      if (unchanged) continue;

      await ng.NativeGeofenceManager.instance.createGeofence(
        _toNativeGeofence(zone, entry.key),
        geofenceCallbackDispatcher,
      );
      logger.i('[Geofencing] Zone enregistrée : ${entry.key} '
          '(${zone.radiusMeters.round()} m)');
    }
  }

  Future<List<String>> registeredZoneIds() async {
    final registered = await ng.NativeGeofenceManager.instance
        .getRegisteredGeofences();
    return registered.map((g) => g.id).toList(growable: false);
  }
}
