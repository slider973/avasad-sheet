import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/timesheet_entry.dart';
import '../../../../../enum/absence_period.dart';
import 'timesheet_appointment.dart';
import 'calendar_error_handler.dart';
import '../../../../../services/logger_service.dart';

/// Custom data source for Syncfusion calendar to handle timesheet entries
class TimesheetAppointmentDataSource extends CalendarDataSource {
  /// Creates a data source with the given timesheet appointments
  TimesheetAppointmentDataSource(List<TimesheetAppointment> appointments) {
    this.appointments = appointments;
  }

  /// Creates a data source from a list of timesheet entries
  factory TimesheetAppointmentDataSource.fromTimesheetEntries(
    List<TimesheetEntry> entries,
  ) {
    try {
      logger.i(
          'Creating appointment data source from ${entries.length} timesheet entries');
      final appointments = <TimesheetAppointment>[];
      int successCount = 0;
      int errorCount = 0;

      for (final entry in entries) {
        try {
          final appointmentsForEntry = _convertEntryToAppointments(entry);
          appointments.addAll(appointmentsForEntry);
          successCount++;
        } catch (e, stackTrace) {
          logger.e('Error converting entry ${entry.id} to appointments',
              error: e, stackTrace: stackTrace);
          errorCount++;
        }
      }

      logger.i(
          'Data source creation completed: $successCount successful, $errorCount errors, ${appointments.length} total appointments');

      if (errorCount > 0) {
        logger.w(
            'Some entries failed to convert: $errorCount out of ${entries.length}');
      }

      return TimesheetAppointmentDataSource(appointments);
    } catch (e, stackTrace) {
      logger.e('Critical error creating appointment data source',
          error: e, stackTrace: stackTrace);
      // Return empty data source instead of crashing
      return TimesheetAppointmentDataSource([]);
    }
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as TimesheetAppointment).startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as TimesheetAppointment).endTime;
  }

  @override
  String getSubject(int index) {
    return (appointments![index] as TimesheetAppointment).subject;
  }

  @override
  Color getColor(int index) {
    return (appointments![index] as TimesheetAppointment).color;
  }

  @override
  String? getNotes(int index) {
    return (appointments![index] as TimesheetAppointment).notes;
  }

  @override
  bool isAllDay(int index) {
    return (appointments![index] as TimesheetAppointment).isAllDay;
  }

  /// Gets all appointments for a specific date
  List<TimesheetAppointment> getAppointmentsForDate(DateTime date) {
    if (appointments == null) return [];

    return appointments!
        .cast<TimesheetAppointment>()
        .where((appointment) => isSameDay(appointment.startTime, date))
        .toList();
  }

  /// Gets the timesheet entry for a specific appointment
  TimesheetEntry? getTimesheetEntry(Appointment appointment) {
    if (appointment is TimesheetAppointment) {
      return appointment.timesheetEntry;
    }
    return null;
  }

  /// Updates the data source with new timesheet entries
  void updateEntries(List<TimesheetEntry> entries) {
    try {
      logger.i('Updating data source with ${entries.length} entries');
      final newAppointments = <TimesheetAppointment>[];
      int successCount = 0;
      int errorCount = 0;

      for (final entry in entries) {
        try {
          final appointmentsForEntry = _convertEntryToAppointments(entry);
          newAppointments.addAll(appointmentsForEntry);
          successCount++;
        } catch (e, stackTrace) {
          logger.e('Error updating entry ${entry.id}',
              error: e, stackTrace: stackTrace);
          errorCount++;
        }
      }

      appointments = newAppointments;
      notifyListeners(CalendarDataSourceAction.reset, newAppointments);

      logger.i(
          'Data source update completed: $successCount successful, $errorCount errors, ${newAppointments.length} total appointments');
    } catch (e, stackTrace) {
      logger.e('Critical error updating data source',
          error: e, stackTrace: stackTrace);
      // Keep existing appointments on error
      logger.w('Keeping existing appointments due to update error');
    }
  }

  /// Adds a new timesheet entry to the data source
  void addEntry(TimesheetEntry entry) {
    try {
      logger.i('Adding entry ${entry.id} to data source');

      if (entry.dayDate.isEmpty) {
        throw ArgumentError('Entry dayDate cannot be empty');
      }

      final newAppointments = _convertEntryToAppointments(entry);

      if (appointments == null) {
        appointments = newAppointments;
      } else {
        appointments!.addAll(newAppointments);
      }

      notifyListeners(CalendarDataSourceAction.add, newAppointments);
      logger.i(
          'Successfully added ${newAppointments.length} appointments for entry ${entry.id}');
    } catch (e, stackTrace) {
      logger.e('Error adding entry ${entry.id} to data source',
          error: e, stackTrace: stackTrace);
      // Don't add the entry if there's an error
    }
  }

  /// Removes appointments for a specific timesheet entry
  void removeEntry(TimesheetEntry entry) {
    try {
      logger.i('Removing entry ${entry.id} from data source');

      if (appointments == null) {
        logger.w('No appointments to remove from');
        return;
      }

      final appointmentsToRemove = appointments!
          .cast<TimesheetAppointment>()
          .where((appointment) => appointment.timesheetEntry.id == entry.id)
          .toList();

      if (appointmentsToRemove.isEmpty) {
        logger.w('No appointments found for entry ${entry.id}');
        return;
      }

      for (final appointment in appointmentsToRemove) {
        appointments!.remove(appointment);
      }

      notifyListeners(CalendarDataSourceAction.remove, appointmentsToRemove);
      logger.i(
          'Successfully removed ${appointmentsToRemove.length} appointments for entry ${entry.id}');
    } catch (e, stackTrace) {
      logger.e('Error removing entry ${entry.id} from data source',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Updates appointments for a specific timesheet entry
  void updateEntry(TimesheetEntry oldEntry, TimesheetEntry newEntry) {
    try {
      logger.i('Updating entry ${oldEntry.id} to ${newEntry.id}');
      removeEntry(oldEntry);
      addEntry(newEntry);
      logger.i('Successfully updated entry');
    } catch (e, stackTrace) {
      logger.e('Error updating entry ${oldEntry.id}',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Converts a single timesheet entry to one or more appointments
  static List<TimesheetAppointment> _convertEntryToAppointments(
      TimesheetEntry entry) {
    final appointments = <TimesheetAppointment>[];

    try {
      logger.d('Converting entry ${entry.id} with date: ${entry.dayDate}');

      // Validate entry data
      if (entry.dayDate.isEmpty) {
        throw ArgumentError('Entry dayDate is empty for entry ${entry.id}');
      }

      // Parse the date using the expected format (dd-MMM-yy)
      DateTime date;
      try {
        date = DateFormat("dd-MMM-yy", 'en_US').parse(entry.dayDate);
      } catch (parseError) {
        logger.e('Failed to parse date ${entry.dayDate} for entry ${entry.id}',
            error: parseError);
        throw FormatException('Invalid date format: ${entry.dayDate}');
      }

      final normalizedDate = DateTime(date.year, date.month, date.day);
      logger
          .d('Parsed date: ${DateFormat('yyyy-MM-dd').format(normalizedDate)}');

      // Check if this is an absence entry
      final isAbsence = _isAbsenceEntry(entry);
      logger.d('Entry ${entry.id} is absence: $isAbsence');

      if (isAbsence) {
        final absenceAppointments =
            _createAbsenceAppointments(entry, normalizedDate);
        appointments.addAll(absenceAppointments);
        logger.d(
            'Created ${absenceAppointments.length} absence appointments for entry ${entry.id}');
      } else {
        // This is a work entry - create separate appointments for morning and afternoon
        final workAppointments = _createWorkAppointments(entry, normalizedDate);
        appointments.addAll(workAppointments);
        logger.d('Created ${workAppointments.length} work appointment(s) for entry ${entry.id}');
      }
    } catch (e, stackTrace) {
      // Log error but don't crash - skip this entry
      logger.e('Error converting entry ${entry.id} to appointments',
          error: e, stackTrace: stackTrace);

      // Return empty list for this entry to avoid breaking the entire calendar
      return [];
    }

    logger.d(
        'Successfully converted entry ${entry.id} to ${appointments.length} appointments');
    return appointments;
  }

  /// Checks if a timesheet entry represents an absence
  static bool _isAbsenceEntry(TimesheetEntry entry) {
    // First check if entry has any work time entries
    final hasWorkTimeEntries = entry.startMorning.isNotEmpty ||
        entry.endMorning.isNotEmpty ||
        entry.startAfternoon.isNotEmpty ||
        entry.endAfternoon.isNotEmpty;

    // If entry has work times, it's NOT an absence (even if period is set)
    if (hasWorkTimeEntries) {
      logger.d('Entry ${entry.id} is WORK because it has time entries');
      return false;
    }

    // Entry is an absence if it has an absence entity
    if (entry.absence != null) {
      logger.d('Entry ${entry.id} is absence due to absence entity: ${entry.absence}');
      return true;
    }

    // Or if it has an absence period defined AND no work times
    final hasAbsencePeriod = entry.period != null &&
        (entry.period == AbsencePeriod.fullDay.value ||
            entry.period == AbsencePeriod.halfDay.value);

    if (hasAbsencePeriod) {
      logger.d('Entry ${entry.id} is absence due to period: ${entry.period} and no work times');
      return true;
    }

    // Or if it has an absence reason but no work times
    final hasAbsenceReason =
        entry.absenceReason != null && entry.absenceReason!.isNotEmpty;

    if (hasAbsenceReason) {
      logger.d('Entry ${entry.id} is absence due to absenceReason and no work times');
      return true;
    }

    // No absence indicators and no work times - treat as work day with missing data
    logger.d('Entry ${entry.id} is WORK (default - no absence indicators)');
    return false;
  }

  /// Creates work appointments for a timesheet entry (separate morning/afternoon if both exist)
  static List<TimesheetAppointment> _createWorkAppointments(
    TimesheetEntry entry,
    DateTime date,
  ) {
    final appointments = <TimesheetAppointment>[];

    final hasMorning = entry.startMorning.isNotEmpty && entry.endMorning.isNotEmpty;
    final hasAfternoon = entry.startAfternoon.isNotEmpty && entry.endAfternoon.isNotEmpty;

    if (hasMorning && hasAfternoon) {
      // Create two separate appointments for morning and afternoon
      // But use the ORIGINAL entry to preserve full-day status for color calculation
      final morningEntry = entry.copyWith(
        startAfternoon: '',
        endAfternoon: '',
      );
      appointments.add(TimesheetAppointment.fromWorkEntryWithOriginal(
        entry: morningEntry,
        originalEntry: entry, // Pass original to determine colors correctly
        date: date,
      ));

      final afternoonEntry = entry.copyWith(
        startMorning: '',
        endMorning: '',
      );
      appointments.add(TimesheetAppointment.fromWorkEntryWithOriginal(
        entry: afternoonEntry,
        originalEntry: entry, // Pass original to determine colors correctly
        date: date,
      ));
    } else {
      // Create single appointment
      appointments.add(TimesheetAppointment.fromWorkEntry(
        entry: entry,
        date: date,
      ));
    }

    return appointments;
  }

  /// Creates absence appointments for a timesheet entry
  static List<TimesheetAppointment> _createAbsenceAppointments(
    TimesheetEntry entry,
    DateTime date,
  ) {
    try {
      logger.d('Creating absence appointments for entry ${entry.id}');
      final appointments = <TimesheetAppointment>[];

      // Determine absence period
      AbsencePeriod absencePeriod = AbsencePeriod.fullDay;

      if (entry.period == AbsencePeriod.halfDay.value) {
        absencePeriod = AbsencePeriod.halfDay;
      } else if (entry.period == AbsencePeriod.fullDay.value) {
        absencePeriod = AbsencePeriod.fullDay;
      }

      logger.d('Absence period for entry ${entry.id}: ${absencePeriod.value}');

      if (absencePeriod == AbsencePeriod.halfDay) {
        // Half day absence - determine which half and create appropriate appointments
        final hasMorningWork =
            entry.startMorning.isNotEmpty && entry.endMorning.isNotEmpty;
        final hasAfternoonWork =
            entry.startAfternoon.isNotEmpty && entry.endAfternoon.isNotEmpty;

        logger.d(
            'Entry ${entry.id} - Morning work: $hasMorningWork, Afternoon work: $hasAfternoonWork');

        if (hasMorningWork && !hasAfternoonWork) {
          // Morning work, afternoon absence
          try {
            final workEntry = entry.copyWith(
              startAfternoon: '',
              endAfternoon: '',
              period: null,
              absenceReason: null,
            );
            appointments.add(TimesheetAppointment.fromWorkEntry(
              entry: workEntry,
              date: date,
            ));

            appointments.add(TimesheetAppointment.fromAbsenceEntry(
              entry: entry,
              date: date,
              absencePeriod: AbsencePeriod.halfDay,
            ));
            logger.d(
                'Created morning work + afternoon absence appointments for entry ${entry.id}');
          } catch (e, stackTrace) {
            logger.e(
                'Error creating morning work + afternoon absence appointments',
                error: e,
                stackTrace: stackTrace);
            rethrow;
          }
        } else if (!hasMorningWork && hasAfternoonWork) {
          // Morning absence, afternoon work
          try {
            appointments.add(TimesheetAppointment.fromAbsenceEntry(
              entry: entry,
              date: date,
              absencePeriod: AbsencePeriod.halfDay,
            ));

            final workEntry = entry.copyWith(
              startMorning: '',
              endMorning: '',
              period: null,
              absenceReason: null,
            );
            appointments.add(TimesheetAppointment.fromWorkEntry(
              entry: workEntry,
              date: date,
            ));
            logger.d(
                'Created morning absence + afternoon work appointments for entry ${entry.id}');
          } catch (e, stackTrace) {
            logger.e(
                'Error creating morning absence + afternoon work appointments',
                error: e,
                stackTrace: stackTrace);
            rethrow;
          }
        } else {
          // No clear work pattern, default to full day absence
          logger.w(
              'No clear work pattern for half-day entry ${entry.id}, defaulting to full day absence');
          appointments.add(TimesheetAppointment.fromAbsenceEntry(
            entry: entry,
            date: date,
            absencePeriod: AbsencePeriod.fullDay,
          ));
        }
      } else {
        // Full day absence
        try {
          appointments.add(TimesheetAppointment.fromAbsenceEntry(
            entry: entry,
            date: date,
            absencePeriod: AbsencePeriod.fullDay,
          ));
          logger
              .d('Created full day absence appointment for entry ${entry.id}');
        } catch (e, stackTrace) {
          logger.e('Error creating full day absence appointment',
              error: e, stackTrace: stackTrace);
          rethrow;
        }
      }

      logger.d(
          'Successfully created ${appointments.length} absence appointments for entry ${entry.id}');
      return appointments;
    } catch (e, stackTrace) {
      logger.e('Error creating absence appointments for entry ${entry.id}',
          error: e, stackTrace: stackTrace);
      // Return empty list to avoid breaking the calendar
      return [];
    }
  }

  /// Checks if two dates are the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Gets statistics about the appointments
  Map<String, int> getStatistics() {
    if (appointments == null) {
      return {
        'total': 0,
        'workDays': 0,
        'absences': 0,
        'weekendWork': 0,
        'partialDays': 0,
        'overtimeDays': 0,
      };
    }

    final typedAppointments = appointments!.cast<TimesheetAppointment>();

    return {
      'total': typedAppointments.length,
      'workDays': typedAppointments.where((a) => !a.isAbsence).length,
      'absences': typedAppointments.where((a) => a.isAbsence).length,
      'weekendWork': typedAppointments.where((a) => a.isWeekendWork).length,
      'partialDays': typedAppointments.where((a) => a.isPartialWorkDay).length,
      'overtimeDays': typedAppointments
          .where((a) => !a.isAbsence && a.timesheetEntry.hasOvertimeHours)
          .length,
    };
  }

  /// Gets appointments for a date range
  List<TimesheetAppointment> getAppointmentsForDateRange(
      DateTime startDate, DateTime endDate) {
    if (appointments == null) return [];

    return appointments!.cast<TimesheetAppointment>().where((appointment) {
      final appointmentDate = appointment.startTime;
      return appointmentDate
              .isAfter(startDate.subtract(const Duration(days: 1))) &&
          appointmentDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Gets all unique dates that have appointments
  List<DateTime> getAppointmentDates() {
    if (appointments == null) return [];

    final dates = <DateTime>{};
    for (final appointment in appointments!.cast<TimesheetAppointment>()) {
      final date = appointment.startTime;
      dates.add(DateTime(date.year, date.month, date.day));
    }

    return dates.toList()..sort();
  }

  /// Checks if a date has any appointments
  bool hasAppointmentsForDate(DateTime date) {
    return getAppointmentsForDate(date).isNotEmpty;
  }

  /// Gets the total work hours for a specific date
  Duration getTotalWorkHoursForDate(DateTime date) {
    final appointmentsForDate = getAppointmentsForDate(date);
    Duration total = Duration.zero;

    for (final appointment in appointmentsForDate) {
      if (!appointment.isAbsence) {
        total += appointment.timesheetEntry.calculateDailyTotal();
      }
    }

    return total;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final stats = getStatistics();
    return 'TimesheetAppointmentDataSource{total: ${stats['total']}, '
        'workDays: ${stats['workDays']}, absences: ${stats['absences']}}';
  }
}
