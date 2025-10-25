import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/timesheet_appointment_data_source.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/timesheet_appointment.dart';
import 'package:time_sheet/enum/absence_period.dart';
import 'package:time_sheet/enum/overtime_type.dart';

void main() {
  group('Syncfusion Calendar Conversion Logic', () {
    late DateFormat dateFormat;

    setUp(() {
      dateFormat = DateFormat('dd-MMM-yy');
    });

    group('Work Entry Conversion', () {
      test('should convert full work day entry to appointment', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 1,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.isAbsence, false);
        expect(appointment.isPartialWorkDay, false);
        expect(appointment.isWeekendWork, false);
        expect(appointment.subject, contains('Travail'));
        expect(appointment.color, CalendarColorScheme.workDayColor);
        expect(appointment.timesheetEntry.id, entry.id);
      });

      test('should convert partial work day (morning only) to appointment', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 2,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '',
          endAfternoon: '',
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.isAbsence, false);
        expect(appointment.isPartialWorkDay, true);
        expect(appointment.color, CalendarColorScheme.partialWorkColor);
      });

      test('should convert weekend work entry to appointment', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 3,
          dayDate: '28-Sep-25', // Saturday
          dayOfWeekDate: 'Saturday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          hasOvertimeHours: false,
          isWeekendDay: true,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.isAbsence, false);
        expect(appointment.isWeekendWork, true);
        expect(appointment.subject, contains('Travail WE'));
        expect(appointment.color, CalendarColorScheme.weekendWorkColor);
      });

      test('should convert overtime work entry to appointment', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 4,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours total (1 hour overtime)
          hasOvertimeHours: true,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.isAbsence, false);
        expect(appointment.color, CalendarColorScheme.overtimeWorkColor);
        expect(appointment.notes, contains('Heures supplémentaires'));
      });
    });

    group('Absence Entry Conversion', () {
      test('should convert full day absence to appointment', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 5,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
          absenceReason: 'Congé',
          period: AbsencePeriod.fullDay.value,
          hasOvertimeHours: false,
          isWeekendDay: false,
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
        expect(appointment.subject, contains('Absence - Congé'));
        expect(appointment.color, CalendarColorScheme.fullDayAbsenceColor);
        expect(appointment.notes, contains('Motif: Congé'));
      });

      test('should convert half day absence (morning) with afternoon work', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 6,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '',
          endMorning: '',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absenceReason: 'Médecin',
          period: AbsencePeriod.halfDay.value,
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 2);

        // Should have one absence appointment and one work appointment
        final absenceAppointment = appointments.firstWhere((a) => a.isAbsence);
        final workAppointment = appointments.firstWhere((a) => !a.isAbsence);

        expect(absenceAppointment.absencePeriod, AbsencePeriod.halfDay);
        expect(absenceAppointment.subject, contains('Absence ½j - Médecin'));
        expect(
            absenceAppointment.color, CalendarColorScheme.halfDayAbsenceColor);

        expect(workAppointment.isPartialWorkDay, true);
        expect(workAppointment.color, CalendarColorScheme.partialWorkColor);
      });

      test('should convert half day absence (afternoon) with morning work', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 7,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '',
          endAfternoon: '',
          absenceReason: 'Personnel',
          period: AbsencePeriod.halfDay.value,
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 2);

        // Should have one work appointment and one absence appointment
        final workAppointment = appointments.firstWhere((a) => !a.isAbsence);
        final absenceAppointment = appointments.firstWhere((a) => a.isAbsence);

        expect(workAppointment.isPartialWorkDay, true);
        expect(workAppointment.color, CalendarColorScheme.partialWorkColor);

        expect(absenceAppointment.absencePeriod, AbsencePeriod.halfDay);
        expect(absenceAppointment.subject, contains('Absence ½j - Personnel'));
        expect(
            absenceAppointment.color, CalendarColorScheme.halfDayAbsenceColor);
      });
    });

    group('Date Parsing Logic', () {
      test('should parse date correctly from dayDate format', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 8,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        final expectedDate = DateTime(2025, 9, 26);
        expect(appointment.startTime.year, expectedDate.year);
        expect(appointment.startTime.month, expectedDate.month);
        expect(appointment.startTime.day, expectedDate.day);
      });

      test('should handle invalid date format gracefully', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 9,
          dayDate: 'invalid-date',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert - should skip entries with invalid dates
        expect(appointments.length, 0);
      });
    });

    group('Subject Text Generation', () {
      test('should generate correct subject for work with hours and minutes',
          () {
        // Arrange
        final entry = TimesheetEntry(
          id: 10,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:30',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.subject, 'Travail 8h30');
      });

      test('should generate correct subject for work with only hours', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 11,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.subject, 'Travail 8h');
      });
    });

    group('Data Source Operations', () {
      test('should get appointments for specific date', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            id: 12,
            dayDate: '26-Sep-25',
            dayOfWeekDate: 'Thursday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
          TimesheetEntry(
            id: 13,
            dayDate: '27-Sep-25',
            dayOfWeekDate: 'Friday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final appointmentsForDate =
            dataSource.getAppointmentsForDate(DateTime(2025, 9, 26));

        // Assert
        expect(appointmentsForDate.length, 1);
        expect(appointmentsForDate.first.timesheetEntry.id, 12);
      });

      test('should update entries correctly', () {
        // Arrange
        final initialEntries = [
          TimesheetEntry(
            id: 14,
            dayDate: '26-Sep-25',
            dayOfWeekDate: 'Thursday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
        ];

        final updatedEntries = [
          TimesheetEntry(
            id: 15,
            dayDate: '27-Sep-25',
            dayOfWeekDate: 'Friday',
            startMorning: '09:00',
            endMorning: '13:00',
            startAfternoon: '14:00',
            endAfternoon: '18:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(initialEntries);
        expect(dataSource.appointments!.length, 1);

        dataSource.updateEntries(updatedEntries);

        // Assert
        expect(dataSource.appointments!.length, 1);
        final appointment =
            dataSource.appointments!.first as TimesheetAppointment;
        expect(appointment.timesheetEntry.id, 15);
      });

      test('should get statistics correctly', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            id: 16,
            dayDate: '26-Sep-25',
            dayOfWeekDate: 'Thursday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
          TimesheetEntry(
            id: 17,
            dayDate: '27-Sep-25',
            dayOfWeekDate: 'Friday',
            startMorning: '',
            endMorning: '',
            startAfternoon: '',
            endAfternoon: '',
            absenceReason: 'Congé',
            period: AbsencePeriod.fullDay.value,
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
          TimesheetEntry(
            id: 18,
            dayDate: '28-Sep-25',
            dayOfWeekDate: 'Saturday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: true,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final stats = dataSource.getStatistics();

        // Assert
        expect(stats['total'], 3);
        expect(stats['workDays'], 2);
        expect(stats['absences'], 1);
        expect(stats['weekendWork'], 1);
      });
    });

    group('Enhanced Data Source Operations', () {
      test('should get appointments for date range', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            id: 19,
            dayDate: '26-Sep-25',
            dayOfWeekDate: 'Thursday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
          TimesheetEntry(
            id: 20,
            dayDate: '27-Sep-25',
            dayOfWeekDate: 'Friday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
          TimesheetEntry(
            id: 21,
            dayDate: '30-Sep-25',
            dayOfWeekDate: 'Monday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final appointmentsInRange = dataSource.getAppointmentsForDateRange(
          DateTime(2025, 9, 26),
          DateTime(2025, 9, 27),
        );

        // Assert
        expect(appointmentsInRange.length, 2);
        expect(appointmentsInRange.any((a) => a.timesheetEntry.id == 19), true);
        expect(appointmentsInRange.any((a) => a.timesheetEntry.id == 20), true);
        expect(
            appointmentsInRange.any((a) => a.timesheetEntry.id == 21), false);
      });

      test('should get all appointment dates', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            id: 22,
            dayDate: '26-Sep-25',
            dayOfWeekDate: 'Thursday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
          TimesheetEntry(
            id: 23,
            dayDate: '27-Sep-25',
            dayOfWeekDate: 'Friday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final dates = dataSource.getAppointmentDates();

        // Assert
        expect(dates.length, 2);
        expect(dates.first, DateTime(2025, 9, 26));
        expect(dates.last, DateTime(2025, 9, 27));
      });

      test('should check if date has appointments', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            id: 24,
            dayDate: '26-Sep-25',
            dayOfWeekDate: 'Thursday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

        // Assert
        expect(dataSource.hasAppointmentsForDate(DateTime(2025, 9, 26)), true);
        expect(dataSource.hasAppointmentsForDate(DateTime(2025, 9, 27)), false);
      });

      test('should calculate total work hours for date', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            id: 25,
            dayDate: '26-Sep-25',
            dayOfWeekDate: 'Thursday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final totalHours =
            dataSource.getTotalWorkHoursForDate(DateTime(2025, 9, 26));

        // Assert
        expect(totalHours.inHours, 8);
      });
    });

    group('Enhanced Subject Generation', () {
      test('should add overtime indicator to work subject', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 26,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 9 hours total
          hasOvertimeHours: true,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.subject, 'Travail 10h +');
      });

      test('should truncate long absence reasons', () {
        // Arrange
        final entry = TimesheetEntry(
          id: 27,
          dayDate: '26-Sep-25',
          dayOfWeekDate: 'Thursday',
          startMorning: '',
          endMorning: '',
          startAfternoon: '',
          endAfternoon: '',
          absenceReason: 'Rendez-vous médical très important',
          period: AbsencePeriod.fullDay.value,
          hasOvertimeHours: false,
          isWeekendDay: false,
        );

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries([entry]);
        final appointments =
            dataSource.appointments!.cast<TimesheetAppointment>();

        // Assert
        expect(appointments.length, 1);
        final appointment = appointments.first;
        expect(appointment.subject, 'Absence - Rendez-vous ...');
      });
    });

    group('Enhanced Statistics', () {
      test('should include overtime days in statistics', () {
        // Arrange
        final entries = [
          TimesheetEntry(
            id: 28,
            dayDate: '26-Sep-25',
            dayOfWeekDate: 'Thursday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '17:00',
            hasOvertimeHours: false,
            isWeekendDay: false,
          ),
          TimesheetEntry(
            id: 29,
            dayDate: '27-Sep-25',
            dayOfWeekDate: 'Friday',
            startMorning: '08:00',
            endMorning: '12:00',
            startAfternoon: '13:00',
            endAfternoon: '19:00', // 9 hours
            hasOvertimeHours: true,
            isWeekendDay: false,
          ),
        ];

        // Act
        final dataSource =
            TimesheetAppointmentDataSource.fromTimesheetEntries(entries);
        final stats = dataSource.getStatistics();

        // Assert
        expect(stats['total'], 2);
        expect(stats['workDays'], 2);
        expect(stats['overtimeDays'], 1);
      });
    });
  });
}
