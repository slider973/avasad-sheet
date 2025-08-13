enum AnomalyType {
  insufficientHours('insufficient_hours', 'Heures insuffisantes'),
  excessiveHours('excessive_hours', 'Heures excessives'),
  missingEntry('missing_entry', 'Entrée manquante'),
  invalidTimes('invalid_times', 'Heures invalides'),
  scheduleInconsistency('schedule_inconsistency', 'Incohérence d\'horaire'),
  overtime('overtime', 'Heures supplémentaires'),
  missingBreak('missing_break', 'Pause manquante'),
  weekendWork('weekend_work', 'Travail en week-end'),
  holidayWork('holiday_work', 'Travail en jour férié');

  const AnomalyType(this.id, this.displayName);

  final String id;
  final String displayName;

  static AnomalyType? fromId(String id) {
    for (final type in AnomalyType.values) {
      if (type.id == id) return type;
    }
    return null;
  }

  @override
  String toString() => displayName;
}