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

  TimeSheetBloc({
    required this.saveTimesheetEntryUseCase,
    required this.getTodayTimesheetEntryUseCase
  }) : super(TimeSheetDataState(TimesheetEntry(
          DateFormat("dd-MMM-yy").format(DateTime.now()),
          DateFormat.EEEE().format(DateTime.now()),
          '',
          '',
          '',
          '',
        ))) {
    on<TimeSheetEnterEvent>(_updateEnter);
    on<TimeSheetStartBreakEvent>(_updateStartBreak);
    on<TimeSheetEndBreakEvent>(_updateEndBreak);
    on<TimeSheetOutEvent>(_updateUpdate);
    on<LoadTimeSheetDataEvent>(_loadData);
    add(LoadTimeSheetDataEvent());
  }

  _updateEnter(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      TimesheetEntry updatedEntry = TimesheetEntry(
        currentEntry.dayDate,
        currentEntry.dayOfWeekDate,
        DateFormat('HH:mm').format(event.startTime),
        currentEntry.endMorning,
        currentEntry.startAfternoon,
        currentEntry.endAfternoon,
      );
      updatedEntry.id = currentEntry.id;
       await saveTimesheetEntryUseCase.execute(updatedEntry);
      emit(TimeSheetDataState(updatedEntry));
    } else {
      print('non implémenté');
    }
  }

  _updateUpdate(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      TimesheetEntry updatedEntry = TimesheetEntry(
        currentEntry.dayDate,
        currentEntry.dayOfWeekDate,
        currentEntry.startMorning,
        DateFormat('HH:mm').format(event.endTime),
        currentEntry.startAfternoon,
        currentEntry.endAfternoon,
      );
      updatedEntry.id = currentEntry.id;
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
        currentEntry.dayDate,
        currentEntry.dayOfWeekDate,
        currentEntry.startMorning,
        currentEntry.endMorning,
        DateFormat('HH:mm').format(event.startBreakTime),
        currentEntry.endAfternoon,
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
        currentEntry.dayDate,
        currentEntry.dayOfWeekDate,
        currentEntry.startMorning,
        currentEntry.endMorning,
        currentEntry.startAfternoon,
        DateFormat('HH:mm').format(event.endBreakTime),
      );
      updatedEntry.id = currentEntry.id;
      await saveTimesheetEntryUseCase.execute(updatedEntry);
      emit(TimeSheetDataState(updatedEntry));
    } else {
      print('non implémenté');
    }
  }
  Future<void> _loadData(LoadTimeSheetDataEvent event, Emitter<TimeSheetState> emit) async {
      final entry = await getTodayTimesheetEntryUseCase.execute();
      if (entry != null) {
        emit(TimeSheetDataState(entry));
      } else {
        emit(TimeSheetDataState(TimesheetEntry(
          DateFormat("dd-MMM-yy").format(DateTime.now()),
          DateFormat.EEEE().format(DateTime.now()),
          '',
          '',
          '',
          '',
        )));
      }
  }


}
