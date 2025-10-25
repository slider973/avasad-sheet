import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/timesheet_appointment.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/timesheet_appointment_data_source.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/calendar_theme_config.dart';
import 'package:time_sheet/enum/absence_period.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';

void main() {
  group('Syncfusion Calendar Unit Tests', () {
    group('TimesheetAppointment Creation and Properties', () {
      test('should create TimesheetAppointment with all required properties',
          () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 1,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );
        final date = DateTime(2025, 9, 26);

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: date,
        );

        // Assert
        expect(appointment.timesheetEntry, equals(entry));
        expect(appointment.startTime, equals(date));
        expect(appointment.endTime, equals(date.add(const Duration(hours: 1))));
        expect(appointment.isAbsence, false);
        expect(appointment.isAllDay, true);
        expect(appointment.subject, isNotEmpty);
        expect(appointment.color, isA<Color>());
        expect(appointment.notes, isNotNull);
      });

      test('should create work appointment with correct properties', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 2,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );
        final date = DateTime(2025, 9, 26);

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: date,
        );

        // Assert
        expect(appointment.isAbsence, false);
        expect(appointment.isPartialWorkDay, false);
        expect(appointment.isWeekendWork, false);
        expect(appointment.absencePeriod, isNull);
        expect(appointment.color, CalendarColorScheme.workDayColor);
      });

      test('should create partial work day appointment correctly', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 3,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '',
          endAfternoon: '',
        );
        final date = DateTime(2025, 9, 26);

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: date,
        );

        // Assert
        expect(appointment.isPartialWorkDay, true);
        expect(appointment.color, CalendarColorScheme.partialWorkColor);
        expect(appointment.notes, contains('Matin: 08:00 - 12:00'));
      });

      test('should create weekend work appointment correctly', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 4,
          dayDate: '28-Sep-25', // Saturday
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          isWeekendDay: true,
        );
        final date = DateTime(2025, 9, 28);

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: date,
        );

        // Assert
        expect(appointment.isWeekendWork, true);
        expect(appointment.subject, contains('Travail WE'));
        expect(appointment.color, CalendarColorScheme.weekendWorkColor);
        expect(appointment.notes, contains('Travail de week-end'));
      });

      test('should create overtime work appointment correctly', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 5,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours total
          hasOvertimeHours: true,
        );
        final date = DateTime(2025, 9, 26);

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: date,
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.overtimeWorkColor);
        expect(appointment.subject, contains('+'));
        expect(appointment.notes, contains('Heures supplémentaires'));
      });

      test('should create absence appointment correctly', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 6,
          dayDate: '26-Sep-25',
          absenceReason: 'Congé',
          period: AbsencePeriod.fullDay.value,
        );
        final date = DateTime(2025, 9, 26);

        // Act
        final appointment = TimesheetAppointment.fromAbsenceEntry(
          entry: entry,
          date: date,
          absencePeriod: AbsencePeriod.fullDay,
        );

        // Assert
        expect(appointment.isAbsence, true);
        expect(appointment.absencePeriod, AbsencePeriod.fullDay);
        expect(appointment.subject, contains('Absence - Congé'));
        expect(appointment.color, CalendarColorScheme.fullDayAbsenceColor);
        expect(appointment.notes, contains('Motif: Congé'));
      });

      test('should create half-day absence appointment correctly', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 7,
          dayDate: '26-Sep-25',
          absenceReason: 'Médecin',
          period: AbsencePeriod.halfDay.value,
        );
        final date = DateTime(2025, 9, 26);

        // Act
        final appointment = TimesheetAppointment.fromAbsenceEntry(
          entry: entry,
          date: date,
          absencePeriod: AbsencePeriod.halfDay,
        );

        // Assert
        expect(appointment.isAbsence, true);
        expect(appointment.absencePeriod, AbsencePeriod.halfDay);
        expect(appointment.subject, contains('Absence ½j - Médecin'));
        expect(appointment.color, CalendarColorScheme.halfDayAbsenceColor);
      });
    });

    group('TimesheetAppointmentDataSource Methods', () {
      test('should create data source from timesheet entries', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 8,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 9,
            dayDate: '27-Sep-25',
            absenceReason: 'Congé',
            period: AbsencePeriod.fullDay.value,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

        // Assert
        expect(dataSource.appointments, isNotNull);
        expect(dataSource.appointments!.length, 2);
      });

      test('should implement CalendarDataSource methods correctly', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 10,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

        // Act & Assert
        expect(dataSource.getStartTime(0), isA<DateTime>());
        expect(dataSource.getEndTime(0), isA<DateTime>());
        expect(dataSource.getSubject(0), isA<String>());
        expect(dataSource.getColor(0), isA<Color>());
        expect(dataSource.getNotes(0), isA<String>());
        expect(dataSource.isAllDay(0), isA<bool>());
      });

      test('should get appointments for specific date', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 11,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 12,
            dayDate: '27-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final targetDate = DateTime(2025, 9, 26);

        // Act
        final appointmentsForDate =
            dataSource.getAppointmentsForDate(targetDate);

        // Assert
        expect(appointmentsForDate.length, 1);
        expect(appointmentsForDate.first.timesheetEntry.id, 11);
      });

      test('should get timesheet entry from appointment', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 13,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointment = dataSource.appointments!.first;

        // Act
        final retrievedEntry = dataSource.getTimesheetEntry(appointment);

        // Assert
        expect(retrievedEntry, isNotNull);
        expect(retrievedEntry!.id, entry.id);
      });

      test('should update entries correctly', () {
        // Arrange
        final initialEntries = [
          _createMockTimesheetEntry(
            id: 14,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(initialEntries);

        final newEntries = [
          _createMockTimesheetEntry(
            id: 15,
            dayDate: '27-Sep-25',
            startMorning: '09:00',
            endMorning: '13:00',
            startAfternoon: '14:00',
            endAfternoon: '18:00',
          ),
          _createMockTimesheetEntry(
            id: 16,
            dayDate: '28-Sep-25',
            absenceReason: 'Congé',
            period: AbsencePeriod.fullDay.value,
          ),
        ];

        // Act
        dataSource.updateEntries(newEntries);

        // Assert
        expect(dataSource.appointments!.length, 2);
        final appointment =
            dataSource.appointments!.first as TimesheetAppointment;
        expect(appointment.timesheetEntry.id, 15);
      });

      test('should add entry correctly', () {
        // Arrange
        final initialEntries = [
          _createMockTimesheetEntry(
            id: 17,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(initialEntries);
        final newEntry = _createMockTimesheetEntry(
          id: 18,
          dayDate: '27-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        dataSource.addEntry(newEntry);

        // Assert
        expect(dataSource.appointments!.length, 2);
      });

      test('should remove entry correctly', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 19,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 20,
            dayDate: '27-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final entryToRemove = entries.first;

        // Act
        dataSource.removeEntry(entryToRemove);

        // Assert
        expect(dataSource.appointments!.length, 1);
        final remainingAppointment =
            dataSource.appointments!.first as TimesheetAppointment;
        expect(remainingAppointment.timesheetEntry.id, 20);
      });

      test('should update entry correctly', () {
        // Arrange
        final oldEntry = _createMockTimesheetEntry(
          id: 21,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([oldEntry]);

        final newEntry = _createMockTimesheetEntry(
          id: 21,
          dayDate: '26-Sep-25',
          startMorning: '09:00',
          endMorning: '13:00',
          startAfternoon: '14:00',
          endAfternoon: '18:00',
        );

        // Act
        dataSource.updateEntry(oldEntry, newEntry);

        // Assert
        expect(dataSource.appointments!.length, 1);
        final appointment =
            dataSource.appointments!.first as TimesheetAppointment;
        expect(appointment.timesheetEntry.startMorning, '09:00');
      });
    });

    group('Timesheet Entry to Appointment Conversion', () {
      test('should convert work entry to appointment correctly', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 22,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.timesheetEntry.id, entry.id);
        expect(appointment.isAbsence, false);
        expect(appointment.startTime.year, 2025);
        expect(appointment.startTime.month, 9);
        expect(appointment.startTime.day, 26);
      });

      test('should convert absence entry to appointment correctly', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 23,
          dayDate: '26-Sep-25',
          absenceReason: 'Congé',
          period: AbsencePeriod.fullDay.value,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.isAbsence, true);
        expect(appointment.absencePeriod, AbsencePeriod.fullDay);
      });

      test('should convert half-day absence with work to multiple appointments',
          () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 24,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '',
          endAfternoon: '',
          absenceReason: 'Médecin',
          period: AbsencePeriod.halfDay.value,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 2);
        expect(appointments.any((a) => a.isAbsence), true);
        expect(appointments.any((a) => !a.isAbsence), true);
      });

      test('should handle invalid date format gracefully', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 25,
          dayDate: 'invalid-date',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);

        // Assert
        expect(dataSource.appointments!.length, 0);
      });

      test('should handle empty dayDate gracefully', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 26,
          dayDate: '',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);

        // Assert
        expect(dataSource.appointments!.length, 0);
      });
    });

    group('Date Parsing and Formatting Utilities', () {
      test('should parse date in dd-MMM-yy format correctly', () {
        // Arrange
        final testDates = [
          '26-Sep-25',
          '01-Jan-24',
          '31-Dec-25',
          '15-Jun-23',
        ];

        // Act & Assert
        for (final dateString in testDates) {
          final entry = _createMockTimesheetEntry(
            id: 27,
            dayDate: dateString,
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          );

          final dataSource =
              TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
          expect(dataSource.appointments!.length, 1,
              reason: 'Failed to parse date: $dateString');
        }
      });

      test('should handle various invalid date formats', () {
        // Arrange
        final invalidDates = [
          '26/09/25',
          '2025-09-26',
          '26-September-25',
          'Sep-26-25',
          '',
          'invalid',
        ];

        // Act & Assert
        for (final dateString in invalidDates) {
          final entry = _createMockTimesheetEntry(
            id: 28,
            dayDate: dateString,
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          );

          final dataSource =
              TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
          expect(dataSource.appointments!.length, 0,
              reason: 'Should skip invalid date: $dateString');
        }
      });

      test('should normalize dates correctly', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 29,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointment =
            dataSource.appointments!.first as TimesheetAppointment;

        // Assert
        expect(appointment.startTime.hour, 0);
        expect(appointment.startTime.minute, 0);
        expect(appointment.startTime.second, 0);
        expect(appointment.startTime.millisecond, 0);
      });

      test('should handle same day comparison correctly', () {
        // Arrange
        final date1 = DateTime(2025, 9, 26, 8, 30);
        final date2 = DateTime(2025, 9, 26, 17, 45);
        final date3 = DateTime(2025, 9, 27, 8, 30);

        // Act & Assert
        expect(TimesheetAppointmentDataSource.isSameDay(date1, date2), true);
        expect(TimesheetAppointmentDataSource.isSameDay(date1, date3), false);
        expect(TimesheetAppointmentDataSource.isSameDay(date2, date3), false);
      });
    });

    group('Color Assignment Logic', () {
      test('should assign correct color for regular work day', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 30,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.workDayColor);
      });

      test('should assign correct color for partial work day', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 31,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '',
          endAfternoon: '',
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.partialWorkColor);
      });

      test('should assign correct color for weekend work', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 32,
          dayDate: '28-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          isWeekendDay: true,
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 28),
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.weekendWorkColor);
      });

      test('should assign correct color for overtime work', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 33,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00',
          hasOvertimeHours: true,
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.overtimeWorkColor);
      });

      test('should assign correct color for full day absence', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 34,
          dayDate: '26-Sep-25',
          absenceReason: 'Congé',
          period: AbsencePeriod.fullDay.value,
        );

        // Act
        final appointment = TimesheetAppointment.fromAbsenceEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
          absencePeriod: AbsencePeriod.fullDay,
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.fullDayAbsenceColor);
      });

      test('should assign correct color for half day absence', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 35,
          dayDate: '26-Sep-25',
          absenceReason: 'Médecin',
          period: AbsencePeriod.halfDay.value,
        );

        // Act
        final appointment = TimesheetAppointment.fromAbsenceEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
          absencePeriod: AbsencePeriod.halfDay,
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.halfDayAbsenceColor);
      });

      test('should prioritize weekend over overtime color', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 36,
          dayDate: '28-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00',
          hasOvertimeHours: true,
          isWeekendDay: true,
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 28),
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.weekendWorkColor);
      });

      test('should prioritize partial work over overtime color', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 37,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '',
          endAfternoon: '',
          hasOvertimeHours: true,
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
        );

        // Assert
        expect(appointment.color, CalendarColorScheme.partialWorkColor);
      });
    });

    group('Data Source Statistics and Utilities', () {
      test('should calculate statistics correctly', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 38,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 39,
            dayDate: '27-Sep-25',
            absenceReason: 'Congé',
            period: AbsencePeriod.fullDay.value,
          ),
          _createMockTimesheetEntry(
            id: 40,
            dayDate: '28-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            isWeekendDay: true,
          ),
          _createMockTimesheetEntry(
            id: 41,
            dayDate: '29-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '',
            endAfternoon: '',
          ),
          _createMockTimesheetEntry(
            id: 42,
            dayDate: '30-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00',
            hasOvertimeHours: true,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final stats = dataSource.getStatistics();

        // Assert
        expect(stats['total'], 5);
        expect(stats['workDays'], 4);
        expect(stats['absences'], 1);
        expect(stats['weekendWork'], 1);
        expect(stats['partialDays'], 1);
        expect(stats['overtimeDays'], 1);
      });

      test('should get appointments for date range correctly', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 43,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 44,
            dayDate: '27-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 45,
            dayDate: '30-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

        // Act
        final appointmentsInRange = dataSource.getAppointmentsForDateRange(
          DateTime(2025, 9, 26),
          DateTime(2025, 9, 27),
        );

        // Assert
        expect(appointmentsInRange.length, 2);
        expect(appointmentsInRange.any((a) => a.timesheetEntry.id == 43), true);
        expect(appointmentsInRange.any((a) => a.timesheetEntry.id == 44), true);
        expect(
            appointmentsInRange.any((a) => a.timesheetEntry.id == 45), false);
      });

      test('should get all appointment dates correctly', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 46,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 47,
            dayDate: '28-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

        // Act
        final dates = dataSource.getAppointmentDates();

        // Assert
        expect(dates.length, 2);
        expect(dates.contains(DateTime(2025, 9, 26)), true);
        expect(dates.contains(DateTime(2025, 9, 28)), true);
      });

      test('should check if date has appointments correctly', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 48,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

        // Act & Assert
        expect(dataSource.hasAppointmentsForDate(DateTime(2025, 9, 26)), true);
        expect(dataSource.hasAppointmentsForDate(DateTime(2025, 9, 27)), false);
      });

      test('should calculate total work hours for date correctly', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 49,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

        // Act
        final totalHours =
            dataSource.getTotalWorkHoursForDate(DateTime(2025, 9, 26));

        // Assert
        expect(totalHours.inHours, 8);
      });

      test('should handle empty data source gracefully', () {
        // Arrange
        final dataSource = TimesheetAppointmentDataSource([]);

        // Act & Assert
        expect(dataSource.getAppointmentsForDate(DateTime.now()), isEmpty);
        expect(dataSource.getAppointmentDates(), isEmpty);
        expect(dataSource.hasAppointmentsForDate(DateTime.now()), false);
        expect(
            dataSource.getTotalWorkHoursForDate(DateTime.now()), Duration.zero);

        final stats = dataSource.getStatistics();
        expect(stats['total'], 0);
        expect(stats['workDays'], 0);
        expect(stats['absences'], 0);
      });
    });

    group('Subject and Notes Generation', () {
      test('should generate work subject with hours and minutes', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 50,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:30',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
        );

        // Assert
        expect(appointment.subject, 'Travail 8h30');
      });

      test('should generate work subject with only hours', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 51,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
        );

        // Assert
        expect(appointment.subject, 'Travail 8h');
      });

      test('should generate work subject with overtime indicator', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 52,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00',
          hasOvertimeHours: true,
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
        );

        // Assert
        expect(appointment.subject, contains('+'));
      });

      test('should truncate long absence reasons in subject', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 53,
          dayDate: '26-Sep-25',
          absenceReason: 'Rendez-vous médical très important et urgent',
          period: AbsencePeriod.fullDay.value,
        );

        // Act
        final appointment = TimesheetAppointment.fromAbsenceEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
          absencePeriod: AbsencePeriod.fullDay,
        );

        // Assert
        expect(appointment.subject.length, lessThanOrEqualTo(30));
        expect(appointment.subject, contains('...'));
      });

      test('should generate detailed notes for work appointments', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 54,
          dayDate: '26-Sep-25',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00',
          hasOvertimeHours: true,
        );

        // Act
        final appointment = TimesheetAppointment.fromWorkEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
        );

        // Assert
        expect(appointment.notes, contains('Matin: 08:00 - 12:00'));
        expect(appointment.notes, contains('Après-midi: 13:00 - 19:00'));
        expect(appointment.notes, contains('Heures supplémentaires'));
      });

      test('should generate notes for absence appointments', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 55,
          dayDate: '26-Sep-25',
          absenceReason: 'Congé annuel',
          period: AbsencePeriod.fullDay.value,
        );

        // Act
        final appointment = TimesheetAppointment.fromAbsenceEntry(
          entry: entry,
          date: DateTime(2025, 9, 26),
          absencePeriod: AbsencePeriod.fullDay,
        );

        // Assert
        expect(appointment.notes, contains('Motif: Congé annuel'));
        expect(appointment.notes,
            contains('Période: ${AbsencePeriod.fullDay.value}'));
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle null appointments list gracefully', () {
        // Arrange
        final dataSource = TimesheetAppointmentDataSource([]);

        // Act & Assert
        expect(() => dataSource.getAppointmentsForDate(DateTime.now()),
            returnsNormally);
        expect(() => dataSource.getStatistics(), returnsNormally);
        expect(() => dataSource.getAppointmentDates(), returnsNormally);
      });

      test('should handle entry with empty dayDate', () {
        // Arrange
        final entry = _createMockTimesheetEntry(
          id: 56,
          dayDate: '',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
        );

        // Act
        expect(
            () => TimesheetAppointmentDataSource.fromTimesheetEntries([entry]),
            returnsNormally);
      });

      test('should handle entry with null values gracefully', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 57,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
        );

        // Act & Assert
        expect(
            () => TimesheetAppointmentDataSource.fromTimesheetEntries([entry]),
            returnsNormally);
      });

      test('should handle mixed valid and invalid entries', () {
        // Arrange
        final entries = [
          _createMockTimesheetEntry(
            id: 58,
            dayDate: '26-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 59,
            dayDate: 'invalid-date',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
          _createMockTimesheetEntry(
            id: 60,
            dayDate: '27-Sep-25',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

        // Assert
        expect(dataSource.appointments!.length, 2); // Only valid entries
      });
    });
  });
}

/// Helper function to create mock TimesheetEntry objects for testing
TimesheetEntry _createMockTimesheetEntry({
  required int id,
  required String dayDate,
  String dayOfWeekDate = 'Thursday',
  String startMorning = '',
  String endMorning = '',
  String startAfternoon = '',
  String endAfternoon = '',
  String? absenceReason,
  String? period,
  bool hasOvertimeHours = false,
  bool isWeekendDay = false,
  bool isWeekendOvertimeEnabled = true,
  OvertimeType overtimeType = OvertimeType.NONE,
  AbsenceEntity? absence,
}) {
  return TimesheetEntry(
    id: id,
    dayDate: dayDate,
    dayOfWeekDate: dayOfWeekDate,
    startMorning: startMorning,
    endMorning: endMorning,
    startAfternoon: startAfternoon,
    endAfternoon: endAfternoon,
    absenceReason: absenceReason,
    period: period,
    hasOvertimeHours: hasOvertimeHours,
    isWeekendDay: isWeekendDay,
    isWeekendOvertimeEnabled: isWeekendOvertimeEnabled,
    overtimeType: overtimeType,
    absence: absence,
  );
}
