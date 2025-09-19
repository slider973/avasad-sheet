import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:isar/isar.dart';

import '../test_utils.dart';
import '../../lib/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import '../../lib/features/pointage/domain/entities/timesheet_entry.dart';
import '../../lib/services/weekend_detection_service.dart';
import '../../lib/services/weekend_overtime_calculator.dart';
import '../../lib/services/overtime_configuration_service.dart';
import '../../lib/services/timer_service.dart';
import '../../lib/enum/overtime_type.dart';
import '../../lib/utils/time_utils.dart';

// Generate mocks
@GenerateMocks([
  WeekendDetectionService,
  OvertimeConfigurationService,
  TimerService,
])
import 'weekend_workflow_integration_test.mocks.dart';

void main() {
  group('Weekend Workflow Integration Tests', () {
    late Isar isar;
    late MockWeekendDetectionService mockWeekendDetectionService;
    late MockOvertimeConfigurationService mockOvertimeConfigurationService;
    late MockTimerService mockTimerService;
    late WeekendOvertimeCalculator weekendOvertimeCalculator;

    setUpAll(() async {
      isar = await setupTestIsar();
    });

    setUp(() async {
      await isar.writeTxn(() async {
        await isar.timesheetEntryModels.clear();
      });

      mockWeekendDetectionService = MockWeekendDetectionService();
      mockOvertimeConfigurationService = MockOvertimeConfigurationService();
      mockTimerService = MockTimerService();
      weekendOvertimeCalculator = WeekendOvertimeCalculator();

      // Setup default mocks
      when(mockWeekendDetectionService.isWeekend(any)).thenAnswer((invocation) {
        final date = invocation.positionalArguments[0] as DateTime;
        return date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;
      });

      when(mockOvertimeConfigurationService.isWeekendOvertimeEnabled())
          .thenAnswer((_) async => true);

      when(mockOvertimeConfigurationService.getWeekendDays())
          .thenAnswer((_) async => [DateTime.saturday, DateTime.sunday]);
    });

    tearDownAll(() async {
      await isar.close();
    });

    group('End-to-End Weekend Clocking Workflow', () {
      testWidgets('Complete weekend clocking workflow - Saturday',
          (tester) async {
        // Requirement 1.1: Weekend hours automatically marked as overtime
        final saturdayDate = DateTime(2024, 1, 6); // Saturday

        // Simulate clocking in on Saturday morning
        final clockInEntry = TimesheetEntryModel()
          ..dayDate = saturdayDate
          ..clockInTime = DateTime(2024, 1, 6, 9, 0) // 9:00 AM
          ..clockOutTime = null
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(clockInEntry);
        });

        // Simulate clocking out after 8 hours
        clockInEntry.clockOutTime = DateTime(2024, 1, 6, 17, 0); // 5:00 PM
        clockInEntry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(clockInEntry);
        });

        // Verify weekend detection
        expect(clockInEntry.isWeekendDay, isTrue);
        expect(clockInEntry.overtimeType, equals(OvertimeType.WEEKEND_ONLY));

        // Convert to domain entity and verify calculations
        final domainEntry = clockInEntry.toDomain();
        expect(domainEntry.isWeekend, isTrue);
        expect(
            domainEntry.weekendOvertimeHours, equals(const Duration(hours: 8)));
        expect(domainEntry.weekdayOvertimeHours, equals(Duration.zero));
      });

      testWidgets('Complete weekend clocking workflow - Sunday',
          (tester) async {
        final sundayDate = DateTime(2024, 1, 7); // Sunday

        // Simulate a shorter Sunday shift
        final sundayEntry = TimesheetEntryModel()
          ..dayDate = sundayDate
          ..clockInTime = DateTime(2024, 1, 7, 10, 0) // 10:00 AM
          ..clockOutTime = DateTime(2024, 1, 7, 14, 0) // 2:00 PM (4 hours)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        sundayEntry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(sundayEntry);
        });

        final domainEntry = sundayEntry.toDomain();
        expect(domainEntry.isWeekend, isTrue);
        expect(
            domainEntry.weekendOvertimeHours, equals(const Duration(hours: 4)));
      });

      testWidgets('Mixed week with weekend and weekday overtime',
          (tester) async {
        // Create a full week with mixed overtime scenarios
        final entries = <TimesheetEntryModel>[];

        // Monday - Regular day, no overtime
        entries.add(TimesheetEntryModel()
          ..dayDate = DateTime(2024, 1, 1) // Monday
          ..clockInTime = DateTime(2024, 1, 1, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 1, 17, 0) // 8 hours
          ..isWeekendDay = false
          ..hasOvertimeHours = false
          ..overtimeType = OvertimeType.NONE);

        // Tuesday - Weekday overtime
        entries.add(TimesheetEntryModel()
          ..dayDate = DateTime(2024, 1, 2) // Tuesday
          ..clockInTime = DateTime(2024, 1, 2, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 2, 19, 0) // 10 hours
          ..isWeekendDay = false
          ..hasOvertimeHours = true
          ..overtimeType = OvertimeType.WEEKDAY_ONLY);

        // Saturday - Weekend work
        entries.add(TimesheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6) // Saturday
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0) // 8 hours
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY);

        // Sunday - Weekend work
        entries.add(TimesheetEntryModel()
          ..dayDate = DateTime(2024, 1, 7) // Sunday
          ..clockInTime = DateTime(2024, 1, 7, 10, 0)
          ..clockOutTime = DateTime(2024, 1, 7, 16, 0) // 6 hours
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY);

        // Save all entries
        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timesheetEntryModels.put(entry);
          }
        });

        // Calculate weekly summary
        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final summary =
            weekendOvertimeCalculator.calculateMonthlyOvertime(domainEntries);

        // Verify calculations
        expect(summary.weekdayOvertime,
            equals(const Duration(hours: 2))); // Tuesday overtime
        expect(summary.weekendOvertime,
            equals(const Duration(hours: 14))); // Sat + Sun
        expect(summary.totalOvertime, equals(const Duration(hours: 16)));
      });
    });

    group('Weekend Configuration Impact Tests', () {
      testWidgets('Disabling weekend overtime affects calculations',
          (tester) async {
        final saturdayDate = DateTime(2024, 1, 6);

        // Create entry with weekend overtime disabled
        final entry = TimesheetEntryModel()
          ..dayDate = saturdayDate
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = false // Disabled
          ..overtimeType = OvertimeType.NONE;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(domainEntry.isWeekend, isTrue);
        expect(domainEntry.weekendOvertimeHours, equals(Duration.zero));
        expect(domainEntry.overtimeType, equals(OvertimeType.NONE));
      });

      testWidgets('Custom weekend days configuration', (tester) async {
        // Test with Friday-Saturday as weekend days
        when(mockWeekendDetectionService.isWeekend(any))
            .thenAnswer((invocation) {
          final date = invocation.positionalArguments[0] as DateTime;
          return date.weekday == DateTime.friday ||
              date.weekday == DateTime.saturday;
        });

        when(mockOvertimeConfigurationService.getWeekendDays())
            .thenAnswer((_) async => [DateTime.friday, DateTime.saturday]);

        final fridayDate = DateTime(2024, 1, 5); // Friday
        final entry = TimesheetEntryModel()
          ..dayDate = fridayDate
          ..clockInTime = DateTime(2024, 1, 5, 9, 0)
          ..clockOutTime = DateTime(2024, 1, 5, 17, 0)
          ..isWeekendDay = true // Manually set based on custom config
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(
            domainEntry.weekendOvertimeHours, equals(const Duration(hours: 8)));
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('Handles midnight crossing weekend work', (tester) async {
        final saturdayDate = DateTime(2024, 1, 6);

        // Work that crosses midnight (Saturday night to Sunday morning)
        final entry = TimesheetEntryModel()
          ..dayDate = saturdayDate
          ..clockInTime = DateTime(2024, 1, 6, 22, 0) // 10:00 PM Saturday
          ..clockOutTime = DateTime(2024, 1, 7, 6, 0) // 6:00 AM Sunday
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true
          ..overtimeType = OvertimeType.WEEKEND_ONLY;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(domainEntry.isWeekend, isTrue);
        expect(
            domainEntry.weekendOvertimeHours, equals(const Duration(hours: 8)));
      });

      testWidgets('Handles invalid time entries gracefully', (tester) async {
        final entry = TimesheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6)
          ..clockInTime =
              DateTime(2024, 1, 6, 17, 0) // Clock out before clock in
          ..clockOutTime = DateTime(2024, 1, 6, 9, 0)
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        // Should handle invalid times gracefully
        expect(domainEntry.weekendOvertimeHours, equals(Duration.zero));
      });

      testWidgets('Handles null clock out times', (tester) async {
        final entry = TimesheetEntryModel()
          ..dayDate = DateTime(2024, 1, 6)
          ..clockInTime = DateTime(2024, 1, 6, 9, 0)
          ..clockOutTime = null // Still clocked in
          ..isWeekendDay = true
          ..isWeekendOvertimeEnabled = true;

        entry.updateWeekendStatus();

        await isar.writeTxn(() async {
          await isar.timesheetEntryModels.put(entry);
        });

        final domainEntry = entry.toDomain();
        expect(domainEntry.weekendOvertimeHours, equals(Duration.zero));
      });
    });
  });
}
