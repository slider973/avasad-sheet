import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/repositories/timesheet_repository.dart';
import 'package:time_sheet/features/pointage/domain/strategies/anomaly_detector.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/detect_anomalies_with_compensation_usecase.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/insufficient_hours_detector.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/weekly_compensation_detector.dart';

@GenerateMocks([TimesheetRepository])
import 'detect_anomalies_with_compensation_test.mocks.dart';

void main() {
  late DetectAnomaliesWithCompensationUseCase useCase;
  late MockTimesheetRepository mockRepository;
  late List<AnomalyDetector> detectors;
  late WeeklyCompensationDetector weeklyDetector;

  setUp(() {
    mockRepository = MockTimesheetRepository();
    detectors = [InsufficientHoursDetector()];
    weeklyDetector = WeeklyCompensationDetector();
    useCase = DetectAnomaliesWithCompensationUseCase(
      mockRepository,
      detectors,
      weeklyDetector,
    );
  });

  group('DetectAnomaliesWithCompensationUseCase', () {
    test('should mark anomalies as compensated when weekly total is sufficient', () async {
      // Arrange
      final entries = [
        // Semaine 1
        TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '15:00', // 6h (anomalie)
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '02-Jan-24',
          dayOfWeekDate: 'Tuesday',
          startMorning: '07:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '19:00', // 11h (compense)
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '03-Jan-24',
          dayOfWeekDate: 'Wednesday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '18:00', // 9h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '04-Jan-24',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:30', // 8h30
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '05-Jan-24',
          dayOfWeekDate: 'Friday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h (anomalie)
          period: 'JOURNEE',
        ),
      ];
      // Total: 6 + 11 + 9 + 8.5 + 7 = 41.5h (>= 41h30)

      when(mockRepository.findEntriesFromMonthOf(2, 2024)).thenAnswer((_) async => entries);

      // Act
      final result = await useCase.execute(1, 2024);

      // Assert
      final mondayAnomalies = result.where((a) => a.message.contains('01-Jan-24')).toList();
      final fridayAnomalies = result.where((a) => a.message.contains('05-Jan-24')).toList();

      expect(mondayAnomalies.first.isCompensated, true);
      expect(fridayAnomalies.first.isCompensated, true);
      expect(mondayAnomalies.first.compensationReason, contains('Objectif hebdomadaire atteint'));
    });

    test('should not compensate anomalies when weekly total is insufficient', () async {
      // Arrange
      final entries = [
        TimesheetEntry(
          dayDate: '08-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '09-Jan-24',
          dayOfWeekDate: 'Tuesday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '10-Jan-24',
          dayOfWeekDate: 'Wednesday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 8h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '11-Jan-24',
          dayOfWeekDate: 'Thursday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
          period: 'JOURNEE',
        ),
        TimesheetEntry(
          dayDate: '12-Jan-24',
          dayOfWeekDate: 'Friday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '16:00', // 7h
          period: 'JOURNEE',
        ),
      ];
      // Total: 36h (< 41h30)

      when(mockRepository.findEntriesFromMonthOf(2, 2024)).thenAnswer((_) async => entries);

      // Act
      final result = await useCase.execute(1, 2024);

      // Assert
      final dailyAnomalies = result.where((a) => a.detectorId == 'insufficient_hours').toList();
      expect(dailyAnomalies.every((a) => !a.isCompensated), true);

      // Should have a weekly anomaly
      final weeklyAnomaly = result.firstWhere((a) => a.detectorId == 'weekly_insufficient');
      expect(weeklyAnomaly.message, contains('Manque'));
      expect(weeklyAnomaly.message, contains('5h30')); // 41h30 - 36h
    });

    test('should handle partial weeks correctly', () async {
      // Arrange - only 3 days worked
      final entries = [
        TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00', // 8h
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
      ];

      when(mockRepository.findEntriesFromMonthOf(2, 2024)).thenAnswer((_) async => entries);

      // Act
      final result = await useCase.execute(1, 2024);

      // Assert
      // Should not have compensation applied (less than 3 days minimum)
      final compensatedAnomalies = result.where((a) => a.isCompensated).toList();
      expect(compensatedAnomalies, isEmpty);
    });

    test('should group entries by week correctly', () async {
      // Arrange - entries from 2 different weeks
      final entries = [
        // Week 1
        TimesheetEntry(
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '15:00', // 6h
          period: 'JOURNEE',
        ),
        // Week 2
        TimesheetEntry(
          dayDate: '08-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '08:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '15:00', // 6h
          period: 'JOURNEE',
        ),
      ];

      when(mockRepository.findEntriesFromMonthOf(2, 2024)).thenAnswer((_) async => entries);

      // Act
      final result = await useCase.execute(1, 2024);

      // Assert
      final anomalies = result.where((a) => a.detectorId == 'insufficient_hours').toList();
      expect(anomalies.length, 2);
      // Both should not be compensated (insufficient week data)
      expect(anomalies.every((a) => !a.isCompensated), true);
    });
  });
}
