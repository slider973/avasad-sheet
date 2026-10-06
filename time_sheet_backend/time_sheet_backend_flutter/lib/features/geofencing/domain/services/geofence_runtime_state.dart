/// État volatil du géorepérage, persisté entre deux événements.
///
/// L'application peut être tuée entre deux franchissements de zone : tout ce
/// dont le dispatcher d'arrière-plan a besoin pour raisonner doit donc survivre
/// à la mort du processus. Cette classe est un pur objet de domaine : aucune
/// dépendance Flutter, plugin ou base de données.
class GeofenceRuntimeState {
  /// Heure de la dernière sortie de la zone travail en attente de confirmation
  /// de pause (null si aucune sortie n'est en suspens).
  final DateTime? pendingExitAt;

  /// Dernière sortie connue de la zone travail, conservée pour la
  /// réconciliation du soir même après confirmation de la pause.
  final DateTime? lastExitAt;

  /// Horodatage du dernier événement traité, utilisé pour filtrer les doublons.
  final DateTime? lastEventAt;

  /// Identifiant de zone du dernier événement traité.
  final String? lastEventZoneId;

  const GeofenceRuntimeState({
    this.pendingExitAt,
    this.lastExitAt,
    this.lastEventAt,
    this.lastEventZoneId,
  });

  /// Fenêtre de déduplication : le plugin natif documente un bug iOS où, après
  /// un redémarrage, le premier événement est déclenché deux fois.
  static const Duration duplicateWindow = Duration(seconds: 10);

  /// Vrai si l'événement décrit est un doublon du dernier événement traité.
  bool isDuplicate({
    required String zoneId,
    required DateTime at,
    Duration window = duplicateWindow,
  }) {
    final previousAt = lastEventAt;
    if (previousAt == null || lastEventZoneId != zoneId) {
      return false;
    }
    final elapsed = at.difference(previousAt).abs();
    return elapsed < window;
  }

  GeofenceRuntimeState copyWith({
    DateTime? pendingExitAt,
    DateTime? lastExitAt,
    DateTime? lastEventAt,
    String? lastEventZoneId,
    bool clearPendingExitAt = false,
    bool clearLastExitAt = false,
  }) {
    return GeofenceRuntimeState(
      pendingExitAt:
          clearPendingExitAt ? null : (pendingExitAt ?? this.pendingExitAt),
      lastExitAt: clearLastExitAt ? null : (lastExitAt ?? this.lastExitAt),
      lastEventAt: lastEventAt ?? this.lastEventAt,
      lastEventZoneId: lastEventZoneId ?? this.lastEventZoneId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendingExitAt': pendingExitAt?.toIso8601String(),
      'lastExitAt': lastExitAt?.toIso8601String(),
      'lastEventAt': lastEventAt?.toIso8601String(),
      'lastEventZoneId': lastEventZoneId,
    };
  }

  factory GeofenceRuntimeState.fromJson(Map<String, dynamic> json) {
    return GeofenceRuntimeState(
      pendingExitAt: _parseDate(json['pendingExitAt']),
      lastExitAt: _parseDate(json['lastExitAt']),
      lastEventAt: _parseDate(json['lastEventAt']),
      lastEventZoneId: json['lastEventZoneId'] as String?,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GeofenceRuntimeState &&
            other.pendingExitAt == pendingExitAt &&
            other.lastExitAt == lastExitAt &&
            other.lastEventAt == lastEventAt &&
            other.lastEventZoneId == lastEventZoneId;
  }

  @override
  int get hashCode =>
      Object.hash(pendingExitAt, lastExitAt, lastEventAt, lastEventZoneId);

  @override
  String toString() =>
      'GeofenceRuntimeState{pendingExitAt: $pendingExitAt, '
      'lastExitAt: $lastExitAt, lastEventAt: $lastEventAt, '
      'lastEventZoneId: $lastEventZoneId}';
}

/// Contrat de persistance de l'état volatil du géorepérage.
///
/// L'implémentation doit être utilisable depuis un isolate d'arrière-plan :
/// aucune dépendance à GetIt, à un BuildContext ou à un singleton initialisé
/// au démarrage de l'application.
abstract class GeofenceRuntimeStateRepository {
  Future<GeofenceRuntimeState> load();

  Future<void> save(GeofenceRuntimeState state);
}
