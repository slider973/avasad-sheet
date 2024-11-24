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

  SignalerAbsencePeriodeUsecase({
    required this.getTodayTimesheetEntryUseCase,
    required this.saveTimesheetEntryUseCase
  });

  Future<List<Map<String, TimesheetEntry>>> execute(
      TimeSheetSignalerAbsencePeriodeEvent event) async {
    print("🔍 Starting execute with event type: ${event.type}, period: ${event.period}");

    DateTime currentDate = DateTime.utc(
        event.dateDebut.year, event.dateDebut.month, event.dateDebut.day);
    DateTime endDate = DateTime.utc(
        event.dateFin.year, event.dateFin.month, event.dateFin.day);
    List<Map<String, TimesheetEntry>> entries = [];

    print("📅 Date range: ${currentDate} to ${endDate}");

    while (currentDate.isBefore(endDate.add(Duration(days: 1)))) {
      if (currentDate.weekday >= DateTime.monday &&
          currentDate.weekday <= DateTime.friday) {
        final formattedDate = DateFormat("dd-MMM-yy").format(currentDate);
        print("📝 Processing date: ${formattedDate}");

        String absenceReason = event.type == AbsenceMotif.leaveDay.value ||
            event.type == AbsenceMotif.other.value
            ? event.type
            : "${event.type}: ${event.raison}";
        print("📋 Calculated absenceReason: ${absenceReason}");

        final entry = await getTodayTimesheetEntryUseCase.execute(formattedDate);
        print("📎 Retrieved existing entry: ${entry != null ? 'Entry exists' : 'No existing entry'}");
        if (entry != null) {
          print("   absenceReason: ${entry.absenceReason}");
          print("   period: ${entry.period}");
          print("   startMorning: ${entry.startMorning}");
          print("   endMorning: ${entry.endMorning}");
          print("   startAfternoon: ${entry.startAfternoon}");
          print("   endAfternoon: ${entry.endAfternoon}");
        }

        String? startMorning, endMorning, startAfternoon, endAfternoon;

        if (event.period == AbsencePeriod.halfDay.value) {
          if (event.startTime != null && event.endTime != null) {
            final startTimeStr = _formatTimeOfDay(event.startTime!);
            final endTimeStr = _formatTimeOfDay(event.endTime!);
            print("⏰ Half day times: ${startTimeStr} - ${endTimeStr}");

            if (event.startTime!.hour < 12) {
              startMorning = startTimeStr;
              endMorning = endTimeStr;
            } else {
              startAfternoon = startTimeStr;
              endAfternoon = endTimeStr;
            }
          }
        }

        print("🕒 Final time values:");
        print("   startMorning: ${startMorning ?? 'null'}");
        print("   endMorning: ${endMorning ?? 'null'}");
        print("   startAfternoon: ${startAfternoon ?? 'null'}");
        print("   endAfternoon: ${endAfternoon ?? 'null'}");

        TimesheetEntry updatedEntry;
        if (entry != null) {
          print("📝 Updating existing entry");
          updatedEntry = entry.copyWith(
            absenceReason: absenceReason,
            period: event.period,
            startMorning: startMorning ?? entry.startMorning ?? '',
            endMorning: endMorning ?? entry.endMorning ?? '',
            startAfternoon: startAfternoon ?? entry.startAfternoon ?? '',
            endAfternoon: endAfternoon ?? entry.endAfternoon ?? '',
            absence: event.absence,
          );
        } else {
          print("📝 Creating new entry");
          updatedEntry = TimesheetEntry(
            dayDate: formattedDate,
            dayOfWeekDate: DateFormat.EEEE().format(currentDate),
            startMorning: startMorning ?? '',
            endMorning: endMorning ?? '',
            startAfternoon: startAfternoon ?? '',
            endAfternoon: endAfternoon ?? '',
            absenceReason: absenceReason,
            period: event.period,
            absence: event.absence,
          );
        }
        print("📋 Updated entry values:");
        print("   absenceReason: ${updatedEntry.absenceReason}");
        print("   period: ${updatedEntry.period}");
        print("   startMorning: ${updatedEntry.startMorning}");
        print("   endMorning: ${updatedEntry.endMorning}");
        print("   startAfternoon: ${updatedEntry.startAfternoon}");
        print("   endAfternoon: ${updatedEntry.endAfternoon}");

        final id = await saveTimesheetEntryUseCase.execute(updatedEntry);
        print("💾 Saved entry with ID: ${id}");

        final finalEntry = updatedEntry.copyWith(id: id);
        print("🏁 Final entry absenceReason: ${finalEntry.absenceReason}");

        entries.add({formattedDate: finalEntry});
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    print("✅ Returning ${entries.length} entries");
    return entries;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}