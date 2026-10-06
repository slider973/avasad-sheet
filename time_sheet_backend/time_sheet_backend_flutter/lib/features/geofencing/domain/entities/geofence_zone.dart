/// Nature d'une zone surveillée.
enum GeofenceKind { work, home }

/// Zone géographique circulaire surveillée par le géorepérage.
class GeofenceZone {
  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final GeofenceKind kind;

  const GeofenceZone({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.kind,
    this.radiusMeters = 150,
  });

  GeofenceZone copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    GeofenceKind? kind,
  }) {
    return GeofenceZone(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      kind: kind ?? this.kind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'kind': kind.name,
    };
  }

  factory GeofenceZone.fromJson(Map<String, dynamic> json) {
    return GeofenceZone(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 150,
      kind: GeofenceKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => GeofenceKind.work,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GeofenceZone &&
            other.id == id &&
            other.label == label &&
            other.latitude == latitude &&
            other.longitude == longitude &&
            other.radiusMeters == radiusMeters &&
            other.kind == kind;
  }

  @override
  int get hashCode =>
      Object.hash(id, label, latitude, longitude, radiusMeters, kind);

  @override
  String toString() =>
      'GeofenceZone{id: $id, label: $label, kind: ${kind.name}, '
      'latitude: $latitude, longitude: $longitude, '
      'radiusMeters: $radiusMeters}';
}
