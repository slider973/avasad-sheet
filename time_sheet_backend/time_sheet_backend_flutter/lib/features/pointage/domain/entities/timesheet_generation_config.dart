class TimesheetGenerationConfig {
  final DateTime startTimeMin; // ex: 7h00
  final DateTime startTimeMax; // ex: 8h30
  final DateTime lunchStartMin; // ex: 12h00
  final DateTime lunchStartMax; // ex: 12h30
  final DateTime lunchEndMin; // ex: 13h00
  final DateTime lunchEndMax; // ex: 14h00
  final DateTime endTimeMin; // ex: 16h30
  final DateTime endTimeMax; // ex: 18h18

  TimesheetGenerationConfig({
    required this.startTimeMin,
    required this.startTimeMax,
    required this.lunchStartMin,
    required this.lunchStartMax,
    required this.lunchEndMin,
    required this.lunchEndMax,
    required this.endTimeMin,
    required this.endTimeMax,
  });

  // Créer une configuration par défaut
  factory TimesheetGenerationConfig.defaultConfig() {
    final now = DateTime.now();
    return TimesheetGenerationConfig(
      startTimeMin: DateTime(now.year, now.month, now.day, 7, 0),
      startTimeMax: DateTime(now.year, now.month, now.day, 8, 30),
      lunchStartMin: DateTime(now.year, now.month, now.day, 12, 0),
      lunchStartMax: DateTime(now.year, now.month, now.day, 12, 30),
      lunchEndMin: DateTime(now.year, now.month, now.day, 13, 0),
      lunchEndMax: DateTime(now.year, now.month, now.day, 14, 0),
      endTimeMin: DateTime(now.year, now.month, now.day, 16, 30),
      endTimeMax: DateTime(now.year, now.month, now.day, 18, 18),
    );
  }
}
