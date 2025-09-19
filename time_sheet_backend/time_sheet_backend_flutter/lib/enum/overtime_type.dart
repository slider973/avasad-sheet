/// Enumeration defining different types of overtime work
///
/// This enum is used to categorize overtime hours based on when they occur:
/// - NONE: No overtime hours
/// - WEEKDAY_ONLY: Overtime hours occurring on weekdays only
/// - WEEKEND_ONLY: Overtime hours occurring on weekends only
/// - BOTH: Overtime hours occurring on both weekdays and weekends
enum OvertimeType {
  /// No overtime hours recorded
  NONE,

  /// Overtime hours occurring only on weekdays (Monday-Friday)
  WEEKDAY_ONLY,

  /// Overtime hours occurring only on weekends (Saturday-Sunday)
  WEEKEND_ONLY,

  /// Overtime hours occurring on both weekdays and weekends
  BOTH;

  /// Returns true if this overtime type includes weekday overtime
  bool get includesWeekday => this == WEEKDAY_ONLY || this == BOTH;

  /// Returns true if this overtime type includes weekend overtime
  bool get includesWeekend => this == WEEKEND_ONLY || this == BOTH;

  /// Returns true if no overtime is recorded
  bool get hasNoOvertime => this == NONE;

  /// Returns a human-readable description of the overtime type
  String get description {
    switch (this) {
      case NONE:
        return 'Aucune heure supplémentaire';
      case WEEKDAY_ONLY:
        return 'Heures supplémentaires en semaine uniquement';
      case WEEKEND_ONLY:
        return 'Heures supplémentaires le weekend uniquement';
      case BOTH:
        return 'Heures supplémentaires en semaine et weekend';
    }
  }
}
