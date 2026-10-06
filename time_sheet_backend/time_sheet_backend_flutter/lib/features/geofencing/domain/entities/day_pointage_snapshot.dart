/// Reflet des quatre créneaux de `TimesheetEntry` pour la journée en cours.
///
/// Les créneaux sont au format 'HH:mm', chaîne vide si non pointés.
class DayPointageSnapshot {
  final String startMorning;
  final String endMorning;
  final String startAfternoon;
  final String endAfternoon;

  /// Dernière sortie connue de la zone travail, utilisée pour reconstituer
  /// un pointage de sortie oublié.
  final DateTime? lastExitAt;

  const DayPointageSnapshot({
    this.startMorning = '',
    this.endMorning = '',
    this.startAfternoon = '',
    this.endAfternoon = '',
    this.lastExitAt,
  });

  bool get isDayStarted => startMorning.isNotEmpty;

  bool get isDayClosed => endAfternoon.isNotEmpty;

  DayPointageSnapshot copyWith({
    String? startMorning,
    String? endMorning,
    String? startAfternoon,
    String? endAfternoon,
    DateTime? lastExitAt,
  }) {
    return DayPointageSnapshot(
      startMorning: startMorning ?? this.startMorning,
      endMorning: endMorning ?? this.endMorning,
      startAfternoon: startAfternoon ?? this.startAfternoon,
      endAfternoon: endAfternoon ?? this.endAfternoon,
      lastExitAt: lastExitAt ?? this.lastExitAt,
    );
  }

  @override
  String toString() => 'DayPointageSnapshot{startMorning: $startMorning, '
      'endMorning: $endMorning, startAfternoon: $startAfternoon, '
      'endAfternoon: $endAfternoon, lastExitAt: $lastExitAt}';
}
