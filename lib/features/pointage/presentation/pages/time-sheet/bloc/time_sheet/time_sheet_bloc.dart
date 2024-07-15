import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

import '../../../../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../../../domain/entities/timesheet_entry.dart';
import '../../../../../domain/use_cases/generate_monthly_timesheet_usease.dart';
import '../../../../../domain/use_cases/get_today_timesheet_entry_use_case.dart';
import '../../../../../domain/use_cases/save_timesheet_entry_usecase.dart';

part 'time_sheet_event.dart';

part 'time_sheet_state.dart';

class TimeSheetBloc extends Bloc<TimeSheetEvent, TimeSheetState> {
  final SaveTimesheetEntryUseCase saveTimesheetEntryUseCase;
  final GetTodayTimesheetEntryUseCase getTodayTimesheetEntryUseCase;
  final GenerateMonthlyTimesheetUseCase generateMonthlyTimesheetUseCase;
  final PreferencesBloc preferencesBloc;


  TimeSheetBloc({
    required this.saveTimesheetEntryUseCase,
    required this.getTodayTimesheetEntryUseCase,
    required this.generateMonthlyTimesheetUseCase,
    required this.preferencesBloc,
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
  }

  void _checkGenerationStatus(CheckGenerationStatusEvent event, Emitter<TimeSheetState> emit) {
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
      emit(TimeSheetDataState(updatedEntry));
    } else {
      print('non implémenté');
    }
  }

  void _updateEndDay(event, Emitter<TimeSheetState> emit) async {
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

  void _updateStartBreak(event, Emitter<TimeSheetState> emit) async {
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

  void _updateEndBreak(event, Emitter<TimeSheetState> emit) async {
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

  Future<void> _loadDataTimeSheetData(
      LoadTimeSheetDataEvent event, Emitter<TimeSheetState> emit) async {
    final entry = await getTodayTimesheetEntryUseCase.execute(event.dateStr);
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

  void _updateTimeSheetData(
      UpdateTimeSheetDataEvent event, Emitter<TimeSheetState> emit) {
    emit(TimeSheetDataState(event.entry));
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
  void _onSignalerAbsencePeriode(TimeSheetSignalerAbsencePeriodeEvent event, Emitter<TimeSheetState> emit) async {
    emit(TimeSheetLoading());
    try {
      // Utilisez DateTime.utc pour éviter les problèmes de fuseau horaire
      for (DateTime date = DateTime.utc(event.dateDebut.year, event.dateDebut.month, event.dateDebut.day);
      date.isBefore(event.dateFin.add(Duration(days: 1)));
      date = date.add(Duration(days: 1))) {

        final formattedDate = DateFormat("dd-MMM-yy").format(date);
        final entry = await getTodayTimesheetEntryUseCase.execute(formattedDate);

        final updatedEntry = entry?.copyWith(
          absenceReason: "${event.type}: ${event.raison}",
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
        ) ?? TimesheetEntry(
          dayDate: formattedDate,
          dayOfWeekDate: DateFormat.EEEE().format(date),
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
          absenceReason: "${event.type}: ${event.raison}",
        );

        await saveTimesheetEntryUseCase.execute(updatedEntry);
      }
      emit(TimeSheetAbsenceSignalee());
    } catch (e) {
      emit(TimeSheetErrorState(e.toString()));
    }
  }
}
