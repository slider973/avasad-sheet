import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/weekly_compensation_detector.dart';

void main() {
  late WeeklyCompensationDetector detector;

  setUp(() {
    detector = WeeklyCompensationDetector();
  });

  group('WeeklyCompensationDetector', () {
    test('should detect compensation when weekly total meets target', () {
      // Arrange
      final weekEntries = [
        TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '15:00', // 6h total
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '02-Jan-24',
          dayOfWeekDate: 'Tuesday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 8h total
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '03-Jan-24',
          dayOfWeekDate: 'Wednesday',
          startMorning: '07:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 11h total
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '04-Jan-24',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00', // 9h total
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '05-Jan-24',
          dayOfWeekDate: 'Friday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:30', // 7.5h total
          period: 'JOURNEE',
        ),
      ];
      // Total: 6 + 8 + 11 + 9 + 7.5 = 41.5h

      // Act
      final result = detector.detectWeekly(weekEntries);

      // Assert
      expect(result['isCompensated'], true);
      expect(result['dailyAnomalies'], contains('01-Jan-24')); // Lundi < 8h18
      expect(result['dailyAnomalies'], contains('05-Jan-24')); // Vendredi < 8h18
      expect(result['message'], contains('Objectif hebdomadaire atteint'));
    });

    test('should not compensate when weekly total is below target', () {
      // Arrange
      final weekEntries = [
        TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '02-Jan-24',
          dayOfWeekDate: 'Tuesday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 8h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '03-Jan-24',
          dayOfWeekDate: 'Wednesday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 8h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '04-Jan-24',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '05-Jan-24',
          dayOfWeekDate: 'Friday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
          period: 'JOURNEE',
        ),
      ];
      // Total: 7 + 8 + 8 + 7 + 7 = 37h

      // Act
      final result = detector.detectWeekly(weekEntries);

      // Assert
      expect(result['isCompensated'], false);
      expect(result['message'], contains('Manque'));
      expect(result['message'], contains('4h30')); // 41h30 - 37h = 4h30
    });

    test('should handle empty week entries', () {
      // Act
      final result = detector.detectWeekly([]);

      // Assert
      expect(result['isCompensated'], false);
      expect(result['totalDuration'], Duration.zero);
      expect(result['dailyAnomalies'], isEmpty);
    });

    test('should correctly format duration', () {
      // Arrange
      final weekEntries = [
        TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:30',
          startAfternoon: '13:30',
          endAfternoon: '18:30', // 9h30
          period: 'JOURNEE',
        ),
      ];

      // Act
      final result = detector.detectWeekly(weekEntries);
      final totalDuration = result['totalDuration'] as Duration;

      // Assert
      expect(result['isCompensated'], false); // 9h30 < 41h30
      expect(totalDuration.inHours, 9);
      expect(totalDuration.inMinutes % 60, 30);
      expect(result['message'], contains('Manque'));
    });
  });
}