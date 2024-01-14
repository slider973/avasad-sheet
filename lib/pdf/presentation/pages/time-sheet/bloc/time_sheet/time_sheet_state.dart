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



