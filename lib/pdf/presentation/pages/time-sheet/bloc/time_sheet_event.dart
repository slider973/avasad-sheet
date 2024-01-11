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
  const TimeSheetOutEvent();
  @override
  List<Object> get props => [];
}

class TimeSheetStartBreakEvent extends TimeSheetEvent {
  final DateTime startTime;
  const TimeSheetStartBreakEvent(this.startTime);
  @override
  List<Object> get props => [startTime];
}

class TimeSheetEndBreakEvent extends TimeSheetEvent {
  const TimeSheetEndBreakEvent();
  @override
  List<Object> get props => [];
}
