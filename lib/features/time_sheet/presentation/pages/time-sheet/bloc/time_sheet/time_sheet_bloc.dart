import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/entities/timesheet_entry.dart';
import '../../../../../domain/use_cases/get_today_timesheet_entry_use_case.dart';
import '../../../../../domain/use_cases/save_timesheet_entry_usecase.dart';

part 'time_sheet_event.dart';

part 'time_sheet_state.dart';

class TimeSheetBloc extends Bloc<TimeSheetEvent, TimeSheetState> {
  final SaveTimesheetEntryUseCase saveTimesheetEntryUseCase;
  final GetTodayTimesheetEntryUseCase getTodayTimesheetEntryUseCase;

  TimeSheetBloc(
      {required this.saveTimesheetEntryUseCase,
      required this.getTodayTimesheetEntryUseCase})
      : super(TimeSheetDataState(TimesheetEntry(
          dayDate: DateFormat("dd-MMM-yy").format(DateTime.now()),
          dayOfWeekDate: DateFormat.EEEE().format(DateTime.now()),
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
        ))) {
    on<TimeSheetEnterEvent>(_updateEnter);
    on<TimeSheetStartBreakEvent>(_updateStartBreak);
    on<TimeSheetEndBreakEvent>(_updateEndBreak);
    on<TimeSheetOutEvent>(_updateEndDay);
    on<LoadTimeSheetDataEvent>(_loadData);
    add(LoadTimeSheetDataEvent());
  }

  _updateEnter(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      TimesheetEntry updatedEntry = TimesheetEntry(
        id: currentEntry.id,
        dayDate: currentEntry.dayDate,
        dayOfWeekDate: currentEntry.dayOfWeekDate,
        startMorning: DateFormat('HH:mm').format(event.startTime),
        endMorning: currentEntry.endMorning,
        startAfternoon: currentEntry.startAfternoon,
        endAfternoon: currentEntry.endAfternoon,
      );

      await saveTimesheetEntryUseCase.execute(updatedEntry);
      emit(TimeSheetDataState(updatedEntry));
    } else {
      print('non implémenté');
    }
  }

  _updateEndDay(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      TimesheetEntry updatedEntry = TimesheetEntry(
        dayDate: currentEntry.dayDate,
        dayOfWeekDate: currentEntry.dayOfWeekDate,
        startMorning: currentEntry.startMorning,
        endMorning: currentEntry.endMorning,
        startAfternoon: currentEntry.startAfternoon,
        endAfternoon: DateFormat('HH:mm').format(event.endTime),
        id: currentEntry.id,
      );
      await saveTimesheetEntryUseCase.execute(updatedEntry);
      emit(TimeSheetDataState(updatedEntry));
    } else {
      print('non implémenté');
    }
  }

  _updateStartBreak(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      TimesheetEntry updatedEntry = TimesheetEntry(
        id: currentEntry.id,
        dayDate: currentEntry.dayDate,
        dayOfWeekDate: currentEntry.dayOfWeekDate,
        startMorning: currentEntry.startMorning,
        endMorning: DateFormat('HH:mm').format(event.startBreakTime),
        startAfternoon: currentEntry.startAfternoon,
        endAfternoon: currentEntry.endAfternoon,
      );
      updatedEntry.id = currentEntry.id;
      await saveTimesheetEntryUseCase.execute(updatedEntry);
      emit(TimeSheetDataState(updatedEntry));
    } else {
      print('non implémenté');
    }
  }

  _updateEndBreak(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      TimesheetEntry updatedEntry = TimesheetEntry(
        id: currentEntry.id,
        dayDate: currentEntry.dayDate,
        dayOfWeekDate: currentEntry.dayOfWeekDate,
        startMorning: currentEntry.startMorning,
        endMorning: currentEntry.endMorning,
        startAfternoon: DateFormat('HH:mm').format(event.endBreakTime),
        endAfternoon: currentEntry.endAfternoon,
      );
      await saveTimesheetEntryUseCase.execute(updatedEntry);
      emit(TimeSheetDataState(updatedEntry));
    } else {
      print('non implémenté');
    }
  }

  Future<void> _loadData(
      LoadTimeSheetDataEvent event, Emitter<TimeSheetState> emit) async {
    final entry = await getTodayTimesheetEntryUseCase.execute();
    if (entry != null) {
      emit(TimeSheetDataState(entry));
    } else {
      emit(TimeSheetDataState(TimesheetEntry(
        dayDate: DateFormat("dd-MMM-yy").format(DateTime.now()),
        dayOfWeekDate: DateFormat.EEEE().format(DateTime.now()),
        startMorning: '',
        endMorning: '',
        startAfternoon: '',
        endAfternoon: '',
      )));
    }
  }
}
