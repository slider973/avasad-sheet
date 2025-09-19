import 'package:equatable/equatable.dart';

/// Résumé des heures supplémentaires pour une validation
/// Contient les informations détaillées sur les heures weekend et semaine
class ValidationOvertimeSummary extends Equatable {
  /// Total des heures supplémentaires de semaine
  final Duration weekdayOvertime;

  /// Total des heures supplémentaires de weekend
  final Duration weekendOvertime;

  /// Total des heures normales
  final Duration regularHours;

  /// Taux de majoration pour les heures supplémentaires de semaine
  final double weekdayOvertimeRate;

  /// Taux de majoration pour les heures supplémentaires de weekend
  final double weekendOvertimeRate;

  /// Nombre de jours travaillés le weekend
  final int weekendDaysWorked;

  /// Nombre de jours avec heures supplémentaires en semaine
  final int weekdayOvertimeDays;

  const ValidationOvertimeSummary({
    required this.weekdayOvertime,
    required this.weekendOvertime,
    required this.regularHours,
    required this.weekdayOvertimeRate,
    required this.weekendOvertimeRate,
    required this.weekendDaysWorked,
    required this.weekdayOvertimeDays,
  });

  /// Total des heures supplémentaires (semaine + weekend)
  Duration get totalOvertime => weekdayOvertime + weekendOvertime;

  /// Total des heures travaillées
  Duration get totalHours => regularHours + totalOvertime;

  /// Indique s'il y a des heures supplémentaires
  bool get hasOvertime => totalOvertime > Duration.zero;

  /// Indique s'il y a des heures supplémentaires de weekend
  bool get hasWeekendOvertime => weekendOvertime > Duration.zero;

  /// Indique s'il y a des heures supplémentaires de semaine
  bool get hasWeekdayOvertime => weekdayOvertime > Duration.zero;

  /// Formate une durée en heures et minutes
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }

  /// Heures supplémentaires de semaine formatées
  String get formattedWeekdayOvertime => _formatDuration(weekdayOvertime);

  /// Heures supplémentaires de weekend formatées
  String get formattedWeekendOvertime => _formatDuration(weekendOvertime);

  /// Total des heures supplémentaires formaté
  String get formattedTotalOvertime => _formatDuration(totalOvertime);

  /// Heures normales formatées
  String get formattedRegularHours => _formatDuration(regularHours);

  /// Total des heures formaté
  String get formattedTotalHours => _formatDuration(totalHours);

  @override
  List<Object?> get props => [
        weekdayOvertime,
        weekendOvertime,
        regularHours,
        weekdayOvertimeRate,
        weekendOvertimeRate,
        weekendDaysWorked,
        weekdayOvertimeDays,
      ];

  @override
  String toString() {
    return 'ValidationOvertimeSummary{'
        'regularHours: $formattedRegularHours, '
        'weekdayOvertime: $formattedWeekdayOvertime (${weekdayOvertimeRate}x), '
        'weekendOvertime: $formattedWeekendOvertime (${weekendOvertimeRate}x), '
        'weekendDaysWorked: $weekendDaysWorked, '
        'weekdayOvertimeDays: $weekdayOvertimeDays'
        '}';
  }
}
