import '../features/pointage/domain/entities/timesheet_entry.dart';
import 'monthly_overtime_calculator.dart';
import '../features/preference/presentation/widgets/overtime_calculation_mode_widget.dart';

/// Service unifié pour calculer les heures supplémentaires
/// Utilise toujours le calcul mensuel avec compensation
class UnifiedOvertimeCalculator {
  final MonthlyOvertimeCalculator _monthlyCalculator;

  UnifiedOvertimeCalculator({
    MonthlyOvertimeCalculator? monthlyCalculator,
  }) : _monthlyCalculator = monthlyCalculator ?? MonthlyOvertimeCalculator();

  /// Calcule les heures supplémentaires (toujours en mode mensuel)
  Future<UnifiedOvertimeSummary> calculateOvertime(
    List<TimesheetEntry> entries, {
    double? weekdayRate,
    double? weekendRate,
  }) async {
    // Toujours utiliser le mode mensuel
    return _calculateWithMonthlyMode(entries,
        weekdayRate: weekdayRate, weekendRate: weekendRate);
  }

  /// Calcul avec le mode mensuel avec compensation
  Future<UnifiedOvertimeSummary> _calculateWithMonthlyMode(
    List<TimesheetEntry> entries, {
    double? weekdayRate,
    double? weekendRate,
  }) async {
    final summary = await _monthlyCalculator.calculateMonthlyOvertime(
      entries,
      weekdayRate: weekdayRate,
      weekendRate: weekendRate,
    );

    return UnifiedOvertimeSummary(
      mode: OvertimeCalculationMode.monthlyWithCompensation,
      regularHours: summary.regularHours,
      weekdayOvertime: summary.weekdayOvertime,
      weekendOvertime: summary.weekendOvertime,
      weekdayOvertimeRate: summary.weekdayOvertimeRate,
      weekendOvertimeRate: summary.weekendOvertimeRate,
      deficitHours: summary.deficitHours,
      compensatedDeficitHours: summary.compensatedDeficitHours,
      workingDaysCount: summary.workingDaysCount,
      weekendDaysWorked: summary.weekendDaysWorked,
    );
  }

  /// Obtient le mode de calcul actuel (toujours mensuel)
  Future<OvertimeCalculationMode> getCurrentMode() async {
    return OvertimeCalculationMode.monthlyWithCompensation;
  }

  /// Change le mode de calcul (ne fait rien - toujours mensuel)
  Future<void> setCalculationMode(OvertimeCalculationMode mode) async {
    // Ne fait rien - le mode est fixé à mensuel
  }
}

/// Résumé unifié des heures supplémentaires
class UnifiedOvertimeSummary {
  final OvertimeCalculationMode mode;
  final Duration regularHours;
  final Duration weekdayOvertime;
  final Duration weekendOvertime;
  final double weekdayOvertimeRate;
  final double weekendOvertimeRate;
  final Duration deficitHours;
  final Duration compensatedDeficitHours;
  final int workingDaysCount;
  final int weekendDaysWorked;

  const UnifiedOvertimeSummary({
    required this.mode,
    required this.regularHours,
    required this.weekdayOvertime,
    required this.weekendOvertime,
    required this.weekdayOvertimeRate,
    required this.weekendOvertimeRate,
    required this.deficitHours,
    required this.compensatedDeficitHours,
    required this.workingDaysCount,
    required this.weekendDaysWorked,
  });

  /// Total des heures supplémentaires
  Duration get totalOvertime => weekdayOvertime + weekendOvertime;

  /// Total des heures travaillées
  Duration get totalHours => regularHours + totalOvertime;

  /// Déficit non compensé (seulement pour le mode mensuel)
  Duration get uncompensatedDeficitHours =>
      deficitHours - compensatedDeficitHours;

  /// Indique s'il y a des heures supplémentaires
  bool get hasOvertime => totalOvertime > Duration.zero;

  /// Indique s'il y a un déficit non compensé
  bool get hasUncompensatedDeficit => uncompensatedDeficitHours > Duration.zero;

  /// Pourcentage de compensation des déficits (seulement pour le mode mensuel)
  double get deficitCompensationPercentage {
    if (deficitHours == Duration.zero) return 100.0;
    return (compensatedDeficitHours.inMinutes / deficitHours.inMinutes) * 100.0;
  }

  /// Formate une durée
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  String get formattedRegularHours => _formatDuration(regularHours);
  String get formattedWeekdayOvertime => _formatDuration(weekdayOvertime);
  String get formattedWeekendOvertime => _formatDuration(weekendOvertime);
  String get formattedTotalOvertime => _formatDuration(totalOvertime);
  String get formattedDeficitHours => _formatDuration(deficitHours);
  String get formattedCompensatedDeficitHours =>
      _formatDuration(compensatedDeficitHours);
  String get formattedUncompensatedDeficitHours =>
      _formatDuration(uncompensatedDeficitHours);

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('UnifiedOvertimeSummary (${mode.displayName}):');
    buffer.writeln('  Heures régulières: $formattedRegularHours');
    buffer.writeln('  Heures sup weekday: $formattedWeekdayOvertime');
    buffer.writeln('  Heures sup weekend: $formattedWeekendOvertime');
    buffer.writeln('  Total heures sup: $formattedTotalOvertime');

    if (mode == OvertimeCalculationMode.monthlyWithCompensation) {
      buffer.writeln('  Déficit total: $formattedDeficitHours');
      buffer.writeln('  Déficit compensé: $formattedCompensatedDeficitHours');
      buffer.writeln('  Déficit restant: $formattedUncompensatedDeficitHours');
      buffer.writeln(
          '  Compensation: ${deficitCompensationPercentage.toStringAsFixed(1)}%');
    }

    buffer.writeln(
        '  Jours travaillés: $workingDaysCount weekday, $weekendDaysWorked weekend');

    return buffer.toString();
  }
}
