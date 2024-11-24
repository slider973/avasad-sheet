import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:time_sheet/features/pointage/use_cases/save_timesheet_entry_usecase.dart';

import '../../../../enum/absence_motif.dart';
import '../../../../enum/absence_period.dart';

import '../domain/entities/timesheet_entry.dart';
import '../presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import 'get_today_timesheet_entry_use_case.dart';

class SignalerAbsencePeriodeUsecase {
  final GetTodayTimesheetEntryUseCase getTodayTimesheetEntryUseCase;
  final SaveTimesheetEntryUseCase saveTimesheetEntryUseCase;

  SignalerAbsencePeriodeUsecase(
      {required this.getTodayTimesheetEntryUseCase,
      required this.saveTimesheetEntryUseCase});

  Future<List<Map<String, TimesheetEntry>>> execute(
      TimeSheetSignalerAbsencePeriodeEvent event) async {
    DateTime currentDate = DateTime.utc(
        event.dateDebut.year, event.dateDebut.month, event.dateDebut.day);
    DateTime endDate = DateTime.utc(
        event.dateFin.year, event.dateFin.month, event.dateFin.day);
    List<Map<String, TimesheetEntry>> entries = [];

    while (currentDate.isBefore(endDate.add(Duration(days: 1)))) {
      if (currentDate.weekday >= DateTime.monday &&
          currentDate.weekday <= DateTime.friday) {
        final formattedDate = DateFormat("dd-MMM-yy").format(currentDate);
        String absenceReason = event.type == AbsenceMotif.leaveDay.value ||
                event.type == AbsenceMotif.other.value
            ? event.type
            : "${event.type}: ${event.raison}";

        final entry =
            await getTodayTimesheetEntryUseCase.execute(formattedDate);

        String? startMorning, endMorning, startAfternoon, endAfternoon;

        if (event.period == AbsencePeriod.halfDay.value) {
          if (event.startTime != null && event.endTime != null) {
            final startTimeStr = _formatTimeOfDay(event.startTime!);
            final endTimeStr = _formatTimeOfDay(event.endTime!);

            if (event.startTime!.hour < 12) {
              // presence le matin
              startMorning = startTimeStr;
              endMorning = endTimeStr;
            } else {
              // presence l'après-midi
              startAfternoon = startTimeStr;
              endAfternoon = endTimeStr;
            }
          }
        }

        final updatedEntry = entry?.copyWith(
              absenceReason: absenceReason,
              period: event.period,
              startMorning: startMorning ?? entry.startMorning ?? '',
              endMorning: endMorning ?? entry.endMorning ?? '',
              startAfternoon: startAfternoon ?? entry.startAfternoon ?? '',
              endAfternoon: endAfternoon ?? entry.endAfternoon ?? '',
            ) ??
            TimesheetEntry(
              dayDate: formattedDate,
              dayOfWeekDate: DateFormat.EEEE().format(currentDate),
              startMorning: startMorning ?? '',
              endMorning: endMorning ?? '',
              startAfternoon: startAfternoon ?? '',
              endAfternoon: endAfternoon ?? '',
              absenceReason: absenceReason,
              period: event.period,
            );

        final id = await saveTimesheetEntryUseCase.execute(updatedEntry);
        entries.add({
          formattedDate: updatedEntry.copyWith(
            id: id,
          )
        });
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
    return entries;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
