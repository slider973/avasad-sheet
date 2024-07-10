part of 'time_sheet_bloc.dart';

abstract class TimeSheetEvent extends Equatable {
  const TimeSheetEvent();
}

class TimeSheetInitialEvent extends TimeSheetEvent {
  const TimeSheetInitialEvent();
  @override
  List<Object> get props => [];
}

class TimeSheetEnterEvent extends TimeSheetEvent {
  final DateTime startTime;

  const TimeSheetEnterEvent(this.startTime);

  @override
  List<Object> get props => [startTime];
}

class TimeSheetOutEvent extends TimeSheetEvent {
  final DateTime endTime;
  const TimeSheetOutEvent(this.endTime);
  @override
  List<Object> get props => [endTime];
}

class TimeSheetStartBreakEvent extends TimeSheetEvent {
  final DateTime startBreakTime;
  const TimeSheetStartBreakEvent(this.startBreakTime);
  @override
  List<Object> get props => [startBreakTime];
}

class TimeSheetEndBreakEvent extends TimeSheetEvent {
  final DateTime endBreakTime;
  const TimeSheetEndBreakEvent(this.endBreakTime);
  @override
  List<Object> get props => [endBreakTime];
}

class GetTimesheetEntriesForWeekEvent extends TimeSheetEvent {
  final int weekNumber;

  const GetTimesheetEntriesForWeekEvent(this.weekNumber);

  @override
  List<Object> get props => [weekNumber];
}


class LoadTimeSheetDataEvent extends TimeSheetEvent {
  @override
  List<Object> get props => [];
}

