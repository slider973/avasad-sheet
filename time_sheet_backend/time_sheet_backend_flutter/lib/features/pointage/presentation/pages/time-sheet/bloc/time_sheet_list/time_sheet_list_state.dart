part of 'time_sheet_list_bloc.dart';

abstract class TimeSheetListState extends Equatable {
  const TimeSheetListState();
}

class TimeSheetListInitial extends TimeSheetListState {
  const TimeSheetListInitial();
  @override
  List<Object> get props => [];
}

class TimeSheetListFetchedState extends TimeSheetListState {
  final List<TimesheetEntry> entries;

  const TimeSheetListFetchedState(this.entries);

  @override
  List<Object> get props => [entries];
}



