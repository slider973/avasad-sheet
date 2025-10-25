import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../../domain/entities/timesheet_entry.dart';
import '../../../../../enum/absence_period.dart';
import 'calendar_theme_config.dart';

/// TimesheetAppointment extends Syncfusion's Appointment class to handle timesheet-specific data
class TimesheetAppointment extends Appointment {
  /// The original timesheet entry this appointment represents
  final TimesheetEntry timesheetEntry;

  /// Whether this appointment represents an absence
  final bool isAbsence;

  /// The absence period if this is an absence appointment
  final AbsencePeriod? absencePeriod;

  /// Whether this appointment represents a partial work day
  final bool isPartialWorkDay;

  /// Whether this appointment represents weekend work
  final bool isWeekendWork;

  TimesheetAppointment({
    required this.timesheetEntry,
    required super.startTime,
    required super.endTime,
    required super.subject,
    required super.color,
    this.isAbsence = false,
    this.absencePeriod,
    this.isPartialWorkDay = false,
    this.isWeekendWork = false,
    super.notes,
    super.isAllDay = false,
  });

  /// Creates a work appointment from a timesheet entry
  factory TimesheetAppointment.fromWorkEntry({
    required TimesheetEntry entry,
    required DateTime date,
  }) {
    final isWeekend = entry.isWeekend;
    final isPartial = _isPartialWorkDay(entry);

    // Parse actual work times from entry
    final workTimes = _parseWorkTimes(entry, date);

    return TimesheetAppointment(
      timesheetEntry: entry,
      startTime: workTimes['start']!,
      endTime: workTimes['end']!,
      subject: _buildWorkSubject(entry),
      color: _getWorkColor(entry, isWeekend, isPartial),
      isAbsence: false,
      isPartialWorkDay: isPartial,
      isWeekendWork: isWeekend,
      notes: _buildWorkNotes(entry),
      isAllDay: false, // Show actual time slots
    );
  }

  /// Creates a work appointment with separate display entry but uses original for color/status
  factory TimesheetAppointment.fromWorkEntryWithOriginal({
    required TimesheetEntry entry,
    required TimesheetEntry originalEntry,
    required DateTime date,
  }) {
    final isWeekend = originalEntry.isWeekend;
    final isPartial = _isPartialWorkDay(originalEntry); // Use original for partial check

    // Parse actual work times from display entry
    final workTimes = _parseWorkTimes(entry, date);

    return TimesheetAppointment(
      timesheetEntry: originalEntry, // Store original entry
      startTime: workTimes['start']!,
      endTime: workTimes['end']!,
      subject: _buildWorkSubject(originalEntry), // Use original for subject
      color: _getWorkColor(originalEntry, isWeekend, isPartial), // Use original for color
      isAbsence: false,
      isPartialWorkDay: isPartial,
      isWeekendWork: isWeekend,
      notes: _buildWorkNotes(entry), // Use display entry for notes (shows current slot)
      isAllDay: false,
    );
  }

  /// Creates an absence appointment from a timesheet entry
  factory TimesheetAppointment.fromAbsenceEntry({
    required TimesheetEntry entry,
    required DateTime date,
    required AbsencePeriod absencePeriod,
  }) {
    return TimesheetAppointment(
      timesheetEntry: entry,
      startTime: date,
      endTime: date.add(const Duration(hours: 1)),
      subject: _buildAbsenceSubject(entry, absencePeriod),
      color: _getAbsenceColor(absencePeriod),
      isAbsence: true,
      absencePeriod: absencePeriod,
      notes: _buildAbsenceNotes(entry, absencePeriod),
      isAllDay: true,
    );
  }

  /// Builds the subject text for work appointments
  static String _buildWorkSubject(TimesheetEntry entry) {
    if (entry.isWeekend) {
      return 'Travail WE';
    }

    final duration = entry.calculateDailyTotal();
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    String subject = 'Travail';

    if (hours > 0 && minutes > 0) {
      subject = 'Travail ${hours}h${minutes.toString().padLeft(2, '0')}';
    } else if (hours > 0) {
      subject = 'Travail ${hours}h';
    } else if (minutes > 0) {
      subject = 'Travail ${minutes}min';
    }

    // Add overtime indicator if applicable
    if (entry.hasOvertimeHours) {
      subject += ' +';
    }

    return subject;
  }

  /// Builds the subject text for absence appointments
  static String _buildAbsenceSubject(
      TimesheetEntry entry, AbsencePeriod period) {
    String reason = entry.absenceReason ?? 'Absence';

    // Truncate long reasons for display
    if (reason.length > 15) {
      reason = '${reason.substring(0, 12)}...';
    }

    switch (period) {
      case AbsencePeriod.fullDay:
        return 'Absence - $reason';
      case AbsencePeriod.halfDay:
        return 'Absence ½j - $reason';
    }
  }

  /// Builds notes for work appointments
  static String _buildWorkNotes(TimesheetEntry entry) {
    final notes = <String>[];

    if (entry.startMorning.isNotEmpty && entry.endMorning.isNotEmpty) {
      notes.add('Matin: ${entry.startMorning} - ${entry.endMorning}');
    }

    if (entry.startAfternoon.isNotEmpty && entry.endAfternoon.isNotEmpty) {
      notes.add('Après-midi: ${entry.startAfternoon} - ${entry.endAfternoon}');
    }

    if (entry.hasOvertimeHours) {
      notes.add('Heures supplémentaires');
    }

    if (entry.isWeekend) {
      notes.add('Travail de week-end');
    }

    return notes.join('\n');
  }

  /// Builds notes for absence appointments
  static String _buildAbsenceNotes(TimesheetEntry entry, AbsencePeriod period) {
    final notes = <String>[];

    if (entry.absenceReason != null) {
      notes.add('Motif: ${entry.absenceReason}');
    }

    notes.add('Période: ${period.value}');

    return notes.join('\n');
  }

  /// Gets the appropriate color for work appointments
  static Color _getWorkColor(
      TimesheetEntry entry, bool isWeekend, bool isPartial) {
    if (isWeekend) {
      return CalendarColorScheme.weekendWorkColor;
    }

    if (isPartial) {
      return CalendarColorScheme.partialWorkColor;
    }

    if (entry.hasOvertimeHours) {
      return CalendarColorScheme.overtimeWorkColor;
    }

    return CalendarColorScheme.workDayColor;
  }

  /// Gets the appropriate color for absence appointments
  static Color _getAbsenceColor(AbsencePeriod period) {
    switch (period) {
      case AbsencePeriod.fullDay:
        return CalendarColorScheme.fullDayAbsenceColor;
      case AbsencePeriod.halfDay:
        return CalendarColorScheme.halfDayAbsenceColor;
    }
  }

  /// Checks if a timesheet entry represents a partial work day
  static bool _isPartialWorkDay(TimesheetEntry entry) {
    final hasMorning =
        entry.startMorning.isNotEmpty && entry.endMorning.isNotEmpty;
    final hasAfternoon =
        entry.startAfternoon.isNotEmpty && entry.endAfternoon.isNotEmpty;

    // Partial if only morning or only afternoon is worked
    return (hasMorning && !hasAfternoon) || (!hasMorning && hasAfternoon);
  }

  /// Parses work times from entry and returns start/end DateTime
  static Map<String, DateTime> _parseWorkTimes(TimesheetEntry entry, DateTime date) {
    DateTime? startTime;
    DateTime? endTime;

    // Parse morning times
    if (entry.startMorning.isNotEmpty) {
      startTime = _parseTimeString(entry.startMorning, date);
    }
    if (entry.endMorning.isNotEmpty) {
      endTime = _parseTimeString(entry.endMorning, date);
    }

    // Parse afternoon times (will override if present)
    if (entry.startAfternoon.isNotEmpty && startTime == null) {
      startTime = _parseTimeString(entry.startAfternoon, date);
    }
    if (entry.endAfternoon.isNotEmpty) {
      endTime = _parseTimeString(entry.endAfternoon, date);
    }

    // Fallback to full day if no times found
    return {
      'start': startTime ?? DateTime(date.year, date.month, date.day, 8, 0),
      'end': endTime ?? DateTime(date.year, date.month, date.day, 17, 0),
    };
  }

  /// Parses a time string (HH:mm format) into DateTime
  static DateTime _parseTimeString(String timeStr, DateTime date) {
    try {
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        return DateTime(date.year, date.month, date.day, hour, minute);
      }
    } catch (e) {
      // Invalid format, return default
    }
    return DateTime(date.year, date.month, date.day, 8, 0);
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'TimesheetAppointment{subject: $subject, isAbsence: $isAbsence, '
        'isPartialWorkDay: $isPartialWorkDay, isWeekendWork: $isWeekendWork}';
  }
}


