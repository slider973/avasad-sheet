part of 'time_sheet_bloc.dart';

abstract class TimeSheetState extends Equatable {
  const TimeSheetState();
}

class TimeSheetInitial extends TimeSheetState {
  @override
  List<Object> get props => [];
}

class TimeSheetDataState extends TimeSheetState {
  final TimesheetEntry entry;

  const TimeSheetDataState(this.entry);

  @override
  List<Object> get props => [entry];
}

class TimeSheetErrorState extends TimeSheetState {
  final String message;
  const TimeSheetErrorState(this.message);
  @override
  List<Object> get props => [message];
}

class TimeSheetLoading extends TimeSheetState {
  @override
  List<Object> get props => [];
}

class TimeSheetGenerationCompleted extends TimeSheetState {
  @override
  List<Object> get props => [];
}
class TimeSheetGenerationAvailable extends TimeSheetState {
  @override
  List<Object> get props => [];
}

class TimeSheetAbsenceSignalee extends TimeSheetState {
  @override
  List<Object> get props => [];
}

class TimeSheetWeeklyDataState extends TimeSheetState {
  final TimesheetEntry entry;
  final Duration weeklyWorkTime;
  final Duration weeklyTarget;
  final Duration overtimeHours;

  const TimeSheetWeeklyDataState({
    required this.entry,
    required this.weeklyWorkTime,
    required this.weeklyTarget,
    required this.overtimeHours,
  });

  @override
  List<Object> get props => [entry, weeklyWorkTime, weeklyTarget, overtimeHours];
}

class TimeSheetVacationDataState extends TimeSheetState {
  final TimesheetEntry entry;
  final int remainingVacationDays;

  const TimeSheetVacationDataState({
    required this.entry,
    required this.remainingVacationDays,
  });

  @override
  List<Object> get props => [entry, remainingVacationDays];
}





