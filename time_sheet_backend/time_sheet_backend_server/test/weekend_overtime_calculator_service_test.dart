import 'package:test/test.dart';
import 'dart:convert';
import '../lib/src/services/weekend_overtime_calculator_service.dart';
import '../lib/src/generated/protocol.dart';

void main() {
  group('WeekendOvertimeCalculatorService', () {
    late WeekendOvertimeCalculatorService calculator;

    setUp(() {
      calculator = WeekendOvertimeCalculatorService();
    });

    test('should calculate weekend overtime correctly', () {
      // Create test timesheet data with weekend work
      final entries = [
        {
          'dayDate': '2025-01-18', // Saturday
          'startMorning': '09:00',
          'endMorning': '12:00',
          'startAfternoon': '13:00',
          'endAfternoon': '17:00',
          'isAbsence': false,
          'hasOvertimeHours': false,
        },
        {
          'dayDate': '2025-01-20', // Monday
          'startMorning': '08:00',
          'endMorning': '12:00',
          'startAfternoon': '13:00',
          'endAfternoon': '18:00', // 9 hours total (1 hour overtime)
          'isAbsence': false,
          'hasOvertimeHours': true,
        },
      ];

      final timesheetData = TimesheetData(
        id: 1,
        validationRequestId: 1,
        employeeId: 'EMP001',
        employeeName: 'Test Employee',
        employeeCompany: 'Test Company',
        month: 1,
        year: 2025,
        entries: jsonEncode(entries),
        totalDays: 2.0,
        totalHours: '16:00',
        totalOvertimeHours: '8:00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final summary = calculator.calculateOvertimeSummary(timesheetData);

      // Weekend work: 7 hours (all overtime) - 3h morning + 4h afternoon
      expect(
          summary.weekendOvertimeMinutes, equals(420)); // 7 hours = 420 minutes

      // Weekday work: 1 hour overtime (9 total - 8 standard)
      expect(summary.weekdayOvertimeMinutes, equals(60)); // 1 hour = 60 minutes

      // Regular hours: 8 hours (Monday standard work)
      expect(summary.regularMinutes, equals(480)); // 8 hours = 480 minutes

      expect(summary.hasWeekendOvertime, isTrue);
      expect(summary.hasWeekdayOvertime, isTrue);
      expect(summary.hasOvertime, isTrue);
    });

    test('should handle absence entries correctly', () {
      final entries = [
        {
          'dayDate': '2025-01-18', // Saturday
          'startMorning': '',
          'endMorning': '',
          'startAfternoon': '',
          'endAfternoon': '',
          'isAbsence': true,
          'hasOvertimeHours': false,
        },
      ];

      final timesheetData = TimesheetData(
        id: 1,
        validationRequestId: 1,
        employeeId: 'EMP001',
        employeeName: 'Test Employee',
        employeeCompany: 'Test Company',
        month: 1,
        year: 2025,
        entries: jsonEncode(entries),
        totalDays: 0.0,
        totalHours: '0:00',
        totalOvertimeHours: '0:00',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final summary = calculator.calculateOvertimeSummary(timesheetData);

      expect(summary.weekendOvertimeMinutes, equals(0));
      expect(summary.weekdayOvertimeMinutes, equals(0));
      expect(summary.regularMinutes, equals(0));
      expect(summary.hasOvertime, isFalse);
    });

    test('should format minutes correctly', () {
      expect(calculator.formatMinutesAsHours(480), equals('8h 00m'));
      expect(calculator.formatMinutesAsHours(90), equals('1h 30m'));
      expect(calculator.formatMinutesAsHours(0), equals('0h 00m'));
    });

    test('should format decimal hours correctly', () {
      expect(calculator.formatMinutesAsDecimalHours(480), equals('8.00h'));
      expect(calculator.formatMinutesAsDecimalHours(90), equals('1.50h'));
      expect(calculator.formatMinutesAsDecimalHours(0), equals('0.00h'));
    });
  });
}
