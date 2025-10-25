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

      // Weekday work: 42 minutes overtime (9h total - 8h18 standard)
      expect(
          summary.weekdayOvertimeMinutes, equals(42)); // 9h - 8h18 = 42 minutes

      // Regular hours: 8h18 (Monday standard work)
      expect(summary.regularMinutes, equals(498)); // 8h18 = 498 minutes

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

    test(
        'should calculate monthly overtime with deficit compensation correctly',
        () {
      // Test case: Lundi 6h, Mardi 10h30 (comme dans l'exemple)
      final entries = [
        {
          'dayDate': '2025-01-20', // Lundi - 6h (déficit de 2h18)
          'startMorning': '09:00',
          'endMorning': '12:00',
          'startAfternoon': '13:00',
          'endAfternoon': '16:00', // 6 heures total
          'isAbsence': false,
          'hasOvertimeHours': false,
        },
        {
          'dayDate': '2025-01-21', // Mardi - 10h30 (excès de 2h12)
          'startMorning': '08:00',
          'endMorning': '12:00',
          'startAfternoon': '13:00',
          'endAfternoon': '19:30', // 10h30 total
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
        totalHours: '16:30',
        totalOvertimeHours: '0:00', // Devrait être 0 avec compensation
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final summary = calculator.calculateOvertimeSummary(timesheetData);

      // Total travaillé: 16h30 = 990 minutes
      // Attendu: 2 jours × 8h18 = 2 × 498 = 996 minutes
      // Comme 990 < 996, il n'y a pas d'heures supplémentaires (déficit de 6 minutes)
      expect(summary.weekdayOvertimeMinutes, equals(0));
      expect(summary.regularMinutes, equals(990)); // Tout est régulier
      expect(summary.hasWeekdayOvertime, isFalse);
    });

    test('should calculate overtime when total exceeds expected hours', () {
      // Test case: 2 jours avec plus d'heures que prévu
      final entries = [
        {
          'dayDate': '2025-01-20', // Lundi - 9h
          'startMorning': '08:00',
          'endMorning': '12:00',
          'startAfternoon': '13:00',
          'endAfternoon': '18:00', // 9 heures total
          'isAbsence': false,
          'hasOvertimeHours': true,
        },
        {
          'dayDate': '2025-01-21', // Mardi - 9h
          'startMorning': '08:00',
          'endMorning': '12:00',
          'startAfternoon': '13:00',
          'endAfternoon': '18:00', // 9 heures total
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
        totalHours: '18:00',
        totalOvertimeHours: '1:24', // 18h - (2 × 8h18) = 1h24
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final summary = calculator.calculateOvertimeSummary(timesheetData);

      // Total travaillé: 18h = 1080 minutes
      // Attendu: 2 jours × 8h18 = 2 × 498 = 996 minutes
      // Heures supplémentaires: 1080 - 996 = 84 minutes = 1h24
      expect(summary.weekdayOvertimeMinutes, equals(84)); // 1h24 = 84 minutes
      expect(summary.regularMinutes, equals(996)); // 2 × 8h18
      expect(summary.hasWeekdayOvertime, isTrue);
    });
  });
}
