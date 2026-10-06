import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';

/// Sens du franchissement d'une zone.
enum GeofenceTransition { enter, exit }

/// Franchissement de zone remonté par le service de localisation.
class GeofenceEvent {
  final String zoneId;
  final GeofenceKind kind;
  final GeofenceTransition transition;
  final DateTime at;
  final double? accuracyMeters;

  const GeofenceEvent({
    required this.zoneId,
    required this.kind,
    required this.transition,
    required this.at,
    this.accuracyMeters,
  });

  @override
  String toString() => 'GeofenceEvent{zoneId: $zoneId, kind: ${kind.name}, '
      'transition: ${transition.name}, at: $at, '
      'accuracyMeters: $accuracyMeters}';
}
