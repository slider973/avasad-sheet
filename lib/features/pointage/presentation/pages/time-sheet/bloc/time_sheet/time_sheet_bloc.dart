import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:intl/intl.dart';

//use cases
import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../domain/entities/timesheet_entry.dart';
import '../../../../../use_cases/delete_timesheet_entry_usecase.dart';
import '../../../../../use_cases/generate_monthly_timesheet_usease.dart';
import '../../../../../use_cases/get_overtime_hours_usecase.dart';
import '../../../../../use_cases/get_remaining_vacation_days_usecase.dart';
import '../../../../../use_cases/get_today_timesheet_entry_use_case.dart';
import '../../../../../use_cases/get_weekly_work_time_usecase.dart';
import '../../../../../use_cases/save_timesheet_entry_usecase.dart';
import '../../../../../use_cases/signaler_absence_periode_usecase.dart';


part 'time_sheet_event.dart';

part 'time_sheet_state.dart';

class TimeSheetBloc extends Bloc<TimeSheetEvent, TimeSheetState> {
  final SaveTimesheetEntryUseCase saveTimesheetEntryUseCase;
  final DeleteTimesheetEntryUsecase deleteTimesheetEntryUsecase;
  final GetTodayTimesheetEntryUseCase getTodayTimesheetEntryUseCase;
  final GenerateMonthlyTimesheetUseCase generateMonthlyTimesheetUseCase;
  final PreferencesBloc preferencesBloc;
  final GetWeeklyWorkTimeUseCase getWeeklyWorkTimeUseCase;
  final GetRemainingVacationDaysUseCase getRemainingVacationDaysUseCase;
  final GetOvertimeHoursUseCase getOvertimeHoursUseCase;
  final SignalerAbsencePeriodeUsecase signalerAbsencePeriodeUsecase;

  TimeSheetBloc({
    required this.saveTimesheetEntryUseCase,
    required this.getTodayTimesheetEntryUseCase,
    required this.generateMonthlyTimesheetUseCase,
    required this.deleteTimesheetEntryUsecase,
    required this.preferencesBloc,
    required this.getWeeklyWorkTimeUseCase,
    required this.getRemainingVacationDaysUseCase,
    required this.getOvertimeHoursUseCase,
    required this.signalerAbsencePeriodeUsecase,
  }) : super(TimeSheetInitial()) {
    on<TimeSheetEnterEvent>(_updateEnter);
    on<TimeSheetStartBreakEvent>(_updateStartBreak);
    on<TimeSheetEndBreakEvent>(_updateEndBreak);
    on<TimeSheetOutEvent>(_updateEndDay);
    on<LoadTimeSheetDataEvent>(_loadDataTimeSheetData);
    on<TimeSheetUpdatePointageEvent>(_updatePointage);
    on<UpdateTimeSheetDataEvent>(_updateTimeSheetData);
    on<GenerateMonthlyTimesheetEvent>(_generateMonthlyTimesheet);
    on<CheckGenerationStatusEvent>(_checkGenerationStatus);
    on<TimeSheetSignalerAbsencePeriodeEvent>(_onSignalerAbsencePeriode);
    on<TimeSheetDeleteEntryEvent>(_onDeleteEntry);
    on<CalculateWeeklyDataEvent>(_calculateWeeklyData);
    on<LoadVacationDaysEvent>(_loadVacationDays);
  }

  void _checkGenerationStatus(
      CheckGenerationStatusEvent event, Emitter<TimeSheetState> emit) {
    final preferencesState = preferencesBloc.state;
    if (preferencesState is PreferencesLoaded) {
      final lastGenerationDate = preferencesState.lastGenerationDate;
      final currentDate = DateTime.now();
      if (lastGenerationDate == null ||
          currentDate.month != lastGenerationDate.month ||
          currentDate.year != lastGenerationDate.year) {
        emit(TimeSheetGenerationAvailable());
      } else {
        emit(TimeSheetGenerationCompleted());
      }
    }
  }

  TimesheetEntry _updateEntryTime(
      TimesheetEntry entry, String type, DateTime newDateTime) {
    final newTime = DateFormat('HH:mm').format(newDateTime);
    switch (type) {
      case 'Entrée':
        return entry.copyWith(startMorning: newTime);
      case 'Début pause':
        return entry.copyWith(endMorning: newTime);
      case 'Fin pause':
        return entry.copyWith(startAfternoon: newTime);
      case 'Fin de journée':
        return entry.copyWith(endAfternoon: newTime);
      default:
        return entry;
    }
  }

  void _updatePointage(
      TimeSheetUpdatePointageEvent event, Emitter<TimeSheetState> emit) {
    if (state is TimeSheetDataState) {
      final currentEntry = (state as TimeSheetDataState).entry;
      final updatedEntry =
          _updateEntryTime(currentEntry, event.type, event.newDateTime);
      saveTimesheetEntryUseCase.execute(updatedEntry);
      emit(TimeSheetDataState(updatedEntry));
    }
  }

  void _updateEnter(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      final remainingVacationDays =
          await getRemainingVacationDaysUseCase.execute();
      TimesheetEntry updatedEntry = TimesheetEntry(
        id: currentEntry.id,
        dayDate: currentEntry.dayDate,
        dayOfWeekDate: currentEntry.dayOfWeekDate,
        startMorning: DateFormat('HH:mm').format(event.startTime),
        endMorning: currentEntry.endMorning,
        startAfternoon: currentEntry.startAfternoon,
        endAfternoon: currentEntry.endAfternoon,
      );

      final id = await saveTimesheetEntryUseCase.execute(updatedEntry);
      updatedEntry = updatedEntry.copyWith(id: id);
      emit(TimeSheetDataState(updatedEntry,
          remainingVacationDays: remainingVacationDays));
    } else {
      print('non implémenté');
    }
  }

  void _updateEndDay(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      final remainingVacationDays =
          await getRemainingVacationDaysUseCase.execute();
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
      emit(TimeSheetDataState(updatedEntry,
          remainingVacationDays: remainingVacationDays));
    } else {
      print('non implémenté');
    }
  }

  void _updateStartBreak(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      final remainingVacationDays =
          await getRemainingVacationDaysUseCase.execute();
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
      emit(TimeSheetDataState(updatedEntry,
          remainingVacationDays: remainingVacationDays));
    } else {
      print('non implémenté');
    }
  }

  void _updateEndBreak(event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
      final remainingVacationDays =
          await getRemainingVacationDaysUseCase.execute();
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
      emit(TimeSheetDataState(updatedEntry,
          remainingVacationDays: remainingVacationDays));
    } else {
      print('non implémenté');
    }
  }

  void _onDeleteEntry(
      TimeSheetDeleteEntryEvent event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      final currentEntry = (state as TimeSheetDataState).entry;
      final remainingVacationDays =
          await getRemainingVacationDaysUseCase.execute();
      await deleteTimesheetEntryUsecase.execute(currentEntry);
      emit(TimeSheetDataState(
          currentEntry.copyWith(
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: '',
          ),
          remainingVacationDays: remainingVacationDays));
    }
    if (state is TimeSheetAbsenceSignalee) {
      final currentEntry = (state as TimeSheetAbsenceSignalee).entry;
      final remainingVacationDays =
          await getRemainingVacationDaysUseCase.execute();
      await deleteTimesheetEntryUsecase.execute(currentEntry);
      emit(TimeSheetDataState(
          currentEntry.copyWith(
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: '',
          ),
          remainingVacationDays: remainingVacationDays));
    }
  }

  Future<void> _loadDataTimeSheetData(
      LoadTimeSheetDataEvent event, Emitter<TimeSheetState> emit) async {
    final entry = await getTodayTimesheetEntryUseCase.execute(event.dateStr);
    final remainingVacationDays =
        await getRemainingVacationDaysUseCase.execute();
    if (entry != null) {
      emit(TimeSheetDataState(entry,
          remainingVacationDays: remainingVacationDays));
    } else {
      emit(TimeSheetDataState(
          TimesheetEntry(
            dayDate: DateFormat("dd-MMM-yy").format(DateTime.now()),
            dayOfWeekDate: DateFormat.EEEE().format(DateTime.now()),
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
          ),
          remainingVacationDays: remainingVacationDays));
    }
  }

  Future<void> _updateTimeSheetData(
      UpdateTimeSheetDataEvent event, Emitter<TimeSheetState> emit) async {
    final remainingVacationDays =
        await getRemainingVacationDaysUseCase.execute();
    emit(TimeSheetDataState(event.entry,
        remainingVacationDays: remainingVacationDays));
  }

  Future<void> _generateMonthlyTimesheet(
    GenerateMonthlyTimesheetEvent event,
    Emitter<TimeSheetState> emit,
  ) async {
    emit(TimeSheetLoading());
    try {
      await generateMonthlyTimesheetUseCase.execute();
      final currentDate = DateTime.now();
      preferencesBloc.add(SaveLastGenerationDate(currentDate));
      emit(TimeSheetGenerationCompleted());
    } catch (e) {
      emit(TimeSheetErrorState(e.toString()));
    }
  }

  void _onSignalerAbsencePeriode(TimeSheetSignalerAbsencePeriodeEvent event,
      Emitter<TimeSheetState> emit) async {
    emit(TimeSheetLoading());
    try {
      final daysOff =  await signalerAbsencePeriodeUsecase.execute(event);
      final mapTest = daysOff.firstWhere((element) => element.containsKey(DateFormat("dd-MMM-yy").format(event.selectedDay)));
      print("event.raison ${event.type}");
      emit(TimeSheetAbsenceSignalee(
        absenceReason: event.type,
        entry: mapTest[DateFormat("dd-MMM-yy").format(event.selectedDay)] as TimesheetEntry,
      ));
    } catch (e) {
      emit(TimeSheetErrorState(e.toString()));
    }
  }

  Future<void> _calculateWeeklyData(
      CalculateWeeklyDataEvent event, Emitter<TimeSheetState> emit) async {
    final DateTime selectedDate = event.selectedDate;
    final DateTime startOfWeek =
        selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
    Duration weeklyWorkTime = Duration.zero;

    for (int i = 0; i < 7; i++) {
      final date = startOfWeek.add(Duration(days: i));
      final formattedDate = DateFormat("dd-MMM-yy").format(date);
      final entry = await getTodayTimesheetEntryUseCase.execute(formattedDate);
      if (entry != null) {
        weeklyWorkTime += entry.calculateDailyTotal();
      }
    }

    const weeklyTarget = Duration(hours: 41, minutes: 30);
    final overtimeHours = weeklyWorkTime > weeklyTarget
        ? weeklyWorkTime - weeklyTarget
        : Duration.zero;

    if (state is TimeSheetDataState) {
      final currentEntry = (state as TimeSheetDataState).entry;
      emit(TimeSheetWeeklyDataState(
        entry: currentEntry,
        weeklyWorkTime: weeklyWorkTime,
        weeklyTarget: weeklyTarget,
        overtimeHours: overtimeHours,
      ));
    }
  }

  Future<void> _loadVacationDays(
      LoadVacationDaysEvent event, Emitter<TimeSheetState> emit) async {
    try {
      if (state is TimeSheetDataState) {
        print(" state is TimeSheetDataState");
        final currentEntry = (state as TimeSheetDataState).entry;
        final remainingVacationDays =
            await getRemainingVacationDaysUseCase.execute();
        print("remainingVacationDays $remainingVacationDays");
        emit(TimeSheetDataState(
          currentEntry,
          remainingVacationDays: remainingVacationDays,
        ));
      }
    } catch (e) {
      print("error $e");
      emit(TimeSheetErrorState(e.toString()));
    }
  }

  Future<bool> hasCheckedInForDate(DateTime date) async {
    final formattedDate = DateFormat("dd-MMM-yy").format(date);
    final entry = await getTodayTimesheetEntryUseCase.execute(formattedDate);
    return entry != null && entry.startMorning.isNotEmpty;
  }
}
