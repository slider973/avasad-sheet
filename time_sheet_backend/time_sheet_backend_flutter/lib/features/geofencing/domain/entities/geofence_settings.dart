import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';

/// Réglages utilisateur du pointage automatique par géorepérage.
class GeofenceSettings {
  final bool enabled;
  final bool autoClockIn;
  final bool autoBreak;
  final bool autoClockOut;

  /// Durée minimale hors zone avant de considérer une vraie pause.
  final int breakMinDurationMinutes;

  /// Heure du contrôle d'ambiguïté « pause déjeuner ou reprise ? ».
  final int ambiguityCheckHour;
  final int ambiguityCheckMinute;

  final GeofenceZone? workZone;
  final GeofenceZone? homeZone;

  const GeofenceSettings({
    this.enabled = false,
    this.autoClockIn = true,
    this.autoBreak = true,
    this.autoClockOut = true,
    this.breakMinDurationMinutes = 30,
    this.ambiguityCheckHour = 14,
    this.ambiguityCheckMinute = 0,
    this.workZone,
    this.homeZone,
  });

  GeofenceSettings copyWith({
    bool? enabled,
    bool? autoClockIn,
    bool? autoBreak,
    bool? autoClockOut,
    int? breakMinDurationMinutes,
    int? ambiguityCheckHour,
    int? ambiguityCheckMinute,
    GeofenceZone? workZone,
    GeofenceZone? homeZone,
    bool clearWorkZone = false,
    bool clearHomeZone = false,
  }) {
    return GeofenceSettings(
      enabled: enabled ?? this.enabled,
      autoClockIn: autoClockIn ?? this.autoClockIn,
      autoBreak: autoBreak ?? this.autoBreak,
      autoClockOut: autoClockOut ?? this.autoClockOut,
      breakMinDurationMinutes:
          breakMinDurationMinutes ?? this.breakMinDurationMinutes,
      ambiguityCheckHour: ambiguityCheckHour ?? this.ambiguityCheckHour,
      ambiguityCheckMinute: ambiguityCheckMinute ?? this.ambiguityCheckMinute,
      workZone: clearWorkZone ? null : (workZone ?? this.workZone),
      homeZone: clearHomeZone ? null : (homeZone ?? this.homeZone),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'autoClockIn': autoClockIn,
      'autoBreak': autoBreak,
      'autoClockOut': autoClockOut,
      'breakMinDurationMinutes': breakMinDurationMinutes,
      'ambiguityCheckHour': ambiguityCheckHour,
      'ambiguityCheckMinute': ambiguityCheckMinute,
      'workZone': workZone?.toJson(),
      'homeZone': homeZone?.toJson(),
    };
  }

  factory GeofenceSettings.fromJson(Map<String, dynamic> json) {
    return GeofenceSettings(
      enabled: json['enabled'] as bool? ?? false,
      autoClockIn: json['autoClockIn'] as bool? ?? true,
      autoBreak: json['autoBreak'] as bool? ?? true,
      autoClockOut: json['autoClockOut'] as bool? ?? true,
      breakMinDurationMinutes: json['breakMinDurationMinutes'] as int? ?? 30,
      ambiguityCheckHour: json['ambiguityCheckHour'] as int? ?? 14,
      ambiguityCheckMinute: json['ambiguityCheckMinute'] as int? ?? 0,
      workZone: json['workZone'] == null
          ? null
          : GeofenceZone.fromJson(
              Map<String, dynamic>.from(json['workZone'] as Map)),
      homeZone: json['homeZone'] == null
          ? null
          : GeofenceZone.fromJson(
              Map<String, dynamic>.from(json['homeZone'] as Map)),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GeofenceSettings &&
            other.enabled == enabled &&
            other.autoClockIn == autoClockIn &&
            other.autoBreak == autoBreak &&
            other.autoClockOut == autoClockOut &&
            other.breakMinDurationMinutes == breakMinDurationMinutes &&
            other.ambiguityCheckHour == ambiguityCheckHour &&
            other.ambiguityCheckMinute == ambiguityCheckMinute &&
            other.workZone == workZone &&
            other.homeZone == homeZone;
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        autoClockIn,
        autoBreak,
        autoClockOut,
        breakMinDurationMinutes,
        ambiguityCheckHour,
        ambiguityCheckMinute,
        workZone,
        homeZone,
      );
}
