import 'package:equatable/equatable.dart';

/// Entrée de pointage journalière d'un employé, vue par son manager.
class EmployeeTimesheetEntry extends Equatable {
  final String dayDate;
  final String startMorning;
  final String endMorning;
  final String startAfternoon;
  final String endAfternoon;
  final String absenceReason;
  final bool isWeekendDay;

  const EmployeeTimesheetEntry({
    required this.dayDate,
    required this.startMorning,
    required this.endMorning,
    required this.startAfternoon,
    required this.endAfternoon,
    required this.absenceReason,
    required this.isWeekendDay,
  });

  @override
  List<Object?> get props => [
        dayDate,
        startMorning,
        endMorning,
        startAfternoon,
        endAfternoon,
        absenceReason,
        isWeekendDay,
      ];
}
