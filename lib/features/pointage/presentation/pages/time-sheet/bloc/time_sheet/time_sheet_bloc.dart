import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/cloudsearch/v1.dart';
import 'package:intl/intl.dart';

//use cases
import '../../../../../../absence/data/models/absence.dart';
import '../../../../../../absence/domain/entities/absence_entity.dart';
import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../domain/entities/timesheet_entry.dart';
import '../../../../../use_cases/delete_timesheet_entry_usecase.dart';
import '../../../../../use_cases/generate_monthly_timesheet_usease.dart';
import '../../../../../use_cases/get_monthly_timesheet_entries_usecase.dart';
import '../../../../../use_cases/get_overtime_hours_usecase.dart';
import '../../../../../use_cases/get_remaining_vacation_days_usecase.dart';
import '../../../../../use_cases/get_today_timesheet_entry_use_case.dart';
import '../../../../../use_cases/get_weekly_work_time_usecase.dart';
import '../../../../../use_cases/save_timesheet_entry_usecase.dart';
import '../../../../../use_cases/signaler_absence_periode_usecase.dart';
import '../../../../widgets/pointage_widget/pointage_absence.dart';

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
  final GetMonthlyTimesheetEntriesUseCase getMonthlyTimesheetEntriesUseCase;

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
    required this.getMonthlyTimesheetEntriesUseCase,
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
    on<LoadMonthlyEntriesEvent>(_onLoadMonthlyEntries);
    on<UpdateVacationInfoEvent>(_onUpdateVacationInfo);

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

  Future<TimeSheetDataState> _createTimeSheetDataState(
      TimesheetEntry entry, {
        List<TimesheetEntry> monthlyEntries = const [],
      }) async {
    final vacationInfo = await getRemainingVacationDaysUseCase.execute();

    return TimeSheetDataState(
      entry,
      monthlyEntries: monthlyEntries,
      vacationInfo: vacationInfo,
    );
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
      TimeSheetUpdatePointageEvent event, Emitter<TimeSheetState> emit) async {
    if (state is TimeSheetDataState) {
      final currentEntry = (state as TimeSheetDataState).entry;
      final updatedEntry =
          _updateEntryTime(currentEntry, event.type, event.newDateTime);
      saveTimesheetEntryUseCase.execute(updatedEntry);
      emit(await _createTimeSheetDataState(updatedEntry));
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
      emit(await _createTimeSheetDataState(updatedEntry ));
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
      emit(await _createTimeSheetDataState(updatedEntry));
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
      emit(await _createTimeSheetDataState(updatedEntry));
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
      emit(await _createTimeSheetDataState(updatedEntry));
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
      emit(await _createTimeSheetDataState(
          currentEntry.copyWith(
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: '',
          )));
    }
    if (state is TimeSheetAbsenceSignalee) {
      final currentEntry = (state as TimeSheetAbsenceSignalee).entry;
      final remainingVacationDays =
          await getRemainingVacationDaysUseCase.execute();
      await deleteTimesheetEntryUsecase.execute(currentEntry);
      emit(await _createTimeSheetDataState(
          currentEntry.copyWith(
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: '',
          ),));
    }
  }

  Future<void> _loadDataTimeSheetData(
      LoadTimeSheetDataEvent event, Emitter<TimeSheetState> emit) async {
    final entry = await getTodayTimesheetEntryUseCase.execute(event.dateStr);
    final remainingVacationDays =
        await getRemainingVacationDaysUseCase.execute();
    if (entry != null) {
      emit(await _createTimeSheetDataState(entry));
    } else {
      emit(await _createTimeSheetDataState(
          TimesheetEntry(
            dayDate: event.dateStr,
            dayOfWeekDate: DateFormat.EEEE().format(DateTime.now()),
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
          ),
          ));
    }
  }

  Future<void> _updateTimeSheetData(
      UpdateTimeSheetDataEvent event, Emitter<TimeSheetState> emit) async {
    final remainingVacationDays =
        await getRemainingVacationDaysUseCase.execute();
    emit(await _createTimeSheetDataState(event.entry,
       ));
  }

  Future<void> _generateMonthlyTimesheet(
      GenerateMonthlyTimesheetEvent event,
      Emitter<TimeSheetState> emit,
      ) async {
    print("Starting _generateMonthlyTimesheet");
    emit(TimeSheetLoading());
    try {
      // Lancer le use case pour générer les feuilles de temps
      print("Calling generateMonthlyTimesheetUseCase.execute()");
      await generateMonthlyTimesheetUseCase.execute();

      // Obtenir la date actuelle
      final currentDate = DateTime.now();
      print("Current date: $currentDate");

      // Sauvegarder la date de génération
      print("Saving last generation date in preferencesBloc");
      preferencesBloc.add(SaveLastGenerationDate(currentDate));

      // Émettre l'état de succès
      print("Timesheet generation completed");
      emit(TimeSheetGenerationCompleted());
    } catch (e) {
      // Log de l'erreur
      print("Error while generating monthly timesheet: $e");
      emit(TimeSheetErrorState(e.toString()));
    }
    print("Exiting _generateMonthlyTimesheet");
  }


  void _onSignalerAbsencePeriode(TimeSheetSignalerAbsencePeriodeEvent event,
      Emitter<TimeSheetState> emit) async {
    emit(TimeSheetLoading());
    try {
      final daysOff = await signalerAbsencePeriodeUsecase.execute(event);
      final mapTest = daysOff.firstWhere((element) => element
          .containsKey(DateFormat("dd-MMM-yy").format(event.selectedDay)));
      print("event.raison ${event.type}");
      print(mapTest[DateFormat("dd-MMM-yy").format(event.selectedDay)]);
      // Après avoir signalé l'absence, recharger les données de congés
      final vacationInfo = await getRemainingVacationDaysUseCase.execute();
      add(UpdateVacationInfoEvent(vacationInfo));
      emit(TimeSheetAbsenceSignalee(
        absenceReason: event.type,
        entry: mapTest[DateFormat("dd-MMM-yy").format(event.selectedDay)]
            as TimesheetEntry,
      ));
    } catch (e, stackTrace) {
      emit(TimeSheetErrorState(e.toString()));
      print(stackTrace);
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
        emit(await _createTimeSheetDataState(
          currentEntry,

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

  Future<void> _onLoadMonthlyEntries(
      LoadMonthlyEntriesEvent event, Emitter<TimeSheetState> emit) async {

    // Sauvegarder l'état actuel du pointage avant de charger les statistiques
    final currentState = state;
    emit(TimeSheetLoading());

    try {
      final List<TimesheetEntry> entries =
      await getMonthlyTimesheetEntriesUseCase.execute(event.month);

      TimesheetEntry? currentEntry;

      // Utiliser l'entrée du pointage actuel si elle existe
      if (currentState is TimeSheetDataState) {
        currentEntry = currentState.entry;
      } else {
        // Si pas d'entrée courante, essayer de charger l'entrée d'aujourd'hui
        final today = DateFormat("dd-MMM-yy").format(DateTime.now());
        currentEntry = await getTodayTimesheetEntryUseCase.execute(today);

        // Si toujours pas d'entrée, créer une nouvelle entrée vide pour aujourd'hui
        currentEntry ??= TimesheetEntry(
            dayDate: today,
            dayOfWeekDate: DateFormat('EEEE').format(DateTime.now()),
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
          );
      }

      emit(await _createTimeSheetDataState(currentEntry, monthlyEntries: entries));

    } catch (e) {
      emit(TimeSheetErrorState(
          "Erreur lors du chargement des entrées mensuelles : $e"));
    }
  }
  Future<void> _onUpdateVacationInfo(
      UpdateVacationInfoEvent event,
      Emitter<TimeSheetState> emit,
      ) async {
    if (state is TimeSheetDataState) {
      final currentState = state as TimeSheetDataState;
      emit(TimeSheetDataState(
        currentState.entry,
        monthlyEntries: currentState.monthlyEntries,
        vacationInfo: event.vacationInfo,
      ));
    }
  }

  Future<void> _onLoadVacationDays(
      LoadVacationDaysEvent event,
      Emitter<TimeSheetState> emit
      ) async {
    try {
      if (state is TimeSheetDataState) {
        final currentState = state as TimeSheetDataState;
        final vacationInfo = await getRemainingVacationDaysUseCase.execute();

        emit(TimeSheetDataState(
          currentState.entry,
          monthlyEntries: currentState.monthlyEntries,
          vacationInfo: vacationInfo,
        ));
      }
    } catch (e) {
      print("error $e");
      emit(TimeSheetErrorState(e.toString()));
    }
  }

}
