/// Action de pointage déduite d'un événement de géorepérage.
enum AttendanceAction {
  none,
  clockIn,
  startBreak,
  endBreak,
  clockOut,
  askAmbiguity,
  reconcile,
}

/// Décision produite par la machine à états de pointage.
///
/// [at] est l'heure à inscrire dans la feuille de temps : elle peut être
/// antérieure à l'instant courant (reconstitution d'une sortie manquée).
class AttendanceDecision {
  final AttendanceAction action;
  final DateTime at;
  final String reason;
  final bool needsUserConfirmation;

  const AttendanceDecision({
    required this.action,
    required this.at,
    required this.reason,
    this.needsUserConfirmation = false,
  });

  /// Décision neutre : rien à faire pour le moment.
  factory AttendanceDecision.none({
    required DateTime at,
    String reason = 'Aucune action requise',
  }) {
    return AttendanceDecision(
      action: AttendanceAction.none,
      at: at,
      reason: reason,
    );
  }

  bool get isActionable => action != AttendanceAction.none;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AttendanceDecision &&
            other.action == action &&
            other.at == at &&
            other.reason == reason &&
            other.needsUserConfirmation == needsUserConfirmation;
  }

  @override
  int get hashCode => Object.hash(action, at, reason, needsUserConfirmation);

  @override
  String toString() => 'AttendanceDecision{action: ${action.name}, at: $at, '
      'reason: $reason, needsUserConfirmation: $needsUserConfirmation}';
}
