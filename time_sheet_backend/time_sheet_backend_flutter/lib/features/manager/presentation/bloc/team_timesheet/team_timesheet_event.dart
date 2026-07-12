part of 'team_timesheet_bloc.dart';

abstract class TeamTimesheetEvent extends Equatable {
  const TeamTimesheetEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmployeeTimesheet extends TeamTimesheetEvent {
  final String employeeId;
  final int month;
  final int year;

  const LoadEmployeeTimesheet({
    required this.employeeId,
    required this.month,
    required this.year,
  });

  @override
  List<Object?> get props => [employeeId, month, year];
}
