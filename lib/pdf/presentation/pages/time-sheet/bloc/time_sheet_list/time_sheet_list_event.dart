part of 'time_sheet_list_bloc.dart';

abstract class TimeSheetListEvent extends Equatable {
  const TimeSheetListEvent();
}
class FindTimesheetEntriesEvent extends TimeSheetListEvent {
  const FindTimesheetEntriesEvent();

  @override
  List<Object> get props => [];
}
