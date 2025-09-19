import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:isar/isar.dart';

import '../test_utils.dart';
import '../../lib/features/pointage/data/models/timesheet_entry_model.dart';
import '../../lib/features/validation/domain/entities/validation_overtime_summary.dart';
import '../../lib/features/validation/domain/services/validation_overtime_analyzer.dart';
import '../../lib/features/validation/domain/services/validation_notification_service.dart';
import '../../lib/services/weekend_overtime_calculator.dart';
import '../../lib/enum/overtime_type.dart';

// Generate mocks
@GenerateMocks([
  ValidationNotificationService,
])
import 'weekend_validation_workflow_integration_test.mocks.dart';

void main() {
  group('Weekend Validation Workflow Integration Tests', () {
    late Isar isar;
    late WeekendOvertimeCalculator weekendOvertimeCalculator;
    late ValidationOvertimeAnalyzer validationOvertimeAnalyzer;
    late MockValidationNotificationService mockNotificationService;

    setUpAll(() async {
      isar = await setupTestIsar();
    });

    setUp(() async {
      await isar.writeTxn(() async {
        await isar.timeSheetEntryModels.clear();
      });

      weekendOvertimeCalculator = WeekendOvertimeCalculator();
      validationOvertimeAnalyzer = ValidationOvertimeAnalyzer();
      mockNotificationService = MockValidationNotificationService();

      // Setup default notification service behavior
      when(mockNotificationService.notifyWeekendOvertimeDetected(
        any,
        any,
        any,
      )).thenAnswer((_) async {});
    });

    tearDownAll(() async {
      await isar.close();
    });

    group('Manager Validation Workflow', () {
      testWidgets('Validate timesheet with weekend overtime', (tester) async {
        // Requirement 5.1: Highlight employees who worked weekend
        // Requirement 5.2: Display weekend hours summary before validation

        const employeeName = 'John Doe';
        const month = 1;
        const year = 2024;

        // Create timesheet with weekend work
        final entries = <TimeSheetEntryModel>[
          // Regular weekday
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1) // Monday
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 17, 0)
            ..isWeekendDay = false
            ..hasOvertimeHours = false
            ..overtimeType = OvertimeType.NONE,

          // Weekday with overtime
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 2) // Tuesday
            ..clockInTime = DateTime(2024, 1, 2, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 2, 19, 0) // 10 hours
            ..isWeekendDay = false
            ..hasOvertimeHours = true
            ..overtimeType = OvertimeType.WEEKDAY_ONLY,

          // Weekend work - Saturday
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0) // 8 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Weekend work - Sunday
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime = DateTime(2024, 1, 7, 10, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 16, 0) // 6 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        // Save entries
        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Analyze timesheet for validation
        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final overtimeSummary =
            weekendOvertimeCalculator.calculateMonthlyOvertime(domainEntries);

        final validationSummary =
            validationOvertimeAnalyzer.analyzeEmployeeTimesheet(
          employeeName: employeeName,
          month: month,
          year: year,
          entries: domainEntries,
        );

        // Verify weekend work detection
        expect(validationSummary.hasWeekendWork, isTrue);
        expect(validationSummary.weekendDaysWorked,
            equals(2)); // Saturday and Sunday
        expect(validationSummary.weekendOvertimeHours,
            equals(const Duration(hours: 14)));
        expect(validationSummary.weekdayOvertimeHours,
            equals(const Duration(hours: 2)));
        expect(validationSummary.totalOvertimeHours,
            equals(const Duration(hours: 16)));

        // Verify notification for weekend work
        verify(mockNotificationService.notifyWeekendOvertimeDetected(
          employeeName,
          validationSummary.weekendOvertimeHours,
          validationSummary.weekendDaysWorked,
        )).called(1);

        // Verify validation flags
        expect(validationSummary.requiresManagerAttention, isTrue);
        expect(validationSummary.weekendWorkAlert, isTrue);
      });

      testWidgets('Validate timesheet without weekend work', (tester) async {
        const employeeName = 'Jane Smith';
        const month = 1;
        const year = 2024;

        // Create timesheet with only weekday work
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1) // Monday
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 17, 0)
            ..isWeekendDay = false
            ..hasOvertimeHours = false
            ..overtimeType = OvertimeType.NONE,
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 2) // Tuesday
            ..clockInTime = DateTime(2024, 1, 2, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 2, 18, 0) // 9 hours
            ..isWeekendDay = false
            ..hasOvertimeHours = true
            ..overtimeType = OvertimeType.WEEKDAY_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final validationSummary =
            validationOvertimeAnalyzer.analyzeEmployeeTimesheet(
          employeeName: employeeName,
          month: month,
          year: year,
          entries: domainEntries,
        );

        // Verify no weekend work detected
        expect(validationSummary.hasWeekendWork, isFalse);
        expect(validationSummary.weekendDaysWorked, equals(0));
        expect(validationSummary.weekendOvertimeHours, equals(Duration.zero));
        expect(validationSummary.weekdayOvertimeHours,
            equals(const Duration(hours: 1)));
        expect(validationSummary.weekendWorkAlert, isFalse);

        // Verify no weekend notification sent
        verifyNever(mockNotificationService.notifyWeekendOvertimeDetected(
          any,
          any,
          any,
        ));
      });

      testWidgets('Validate multiple employees with mixed weekend work',
          (tester) async {
        // Test batch validation of multiple employees
        final employeeData = [
          {
            'name': 'Employee A',
            'hasWeekendWork': true,
            'weekendHours': 8,
            'weekdayOvertime': 2,
          },
          {
            'name': 'Employee B',
            'hasWeekendWork': false,
            'weekendHours': 0,
            'weekdayOvertime': 4,
          },
          {
            'name': 'Employee C',
            'hasWeekendWork': true,
            'weekendHours': 16,
            'weekdayOvertime': 0,
          },
        ];

        final validationResults = <ValidationOvertimeSummary>[];

        for (final employee in employeeData) {
          final entries = <TimeSheetEntryModel>[];

          // Create entries based on employee data
          if (employee['hasWeekendWork'] as bool) {
            entries.add(TimeSheetEntryModel()
              ..dayDate = DateTime(2024, 1, 6) // Saturday
              ..clockInTime = DateTime(2024, 1, 6, 9, 0)
              ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
              ..isWeekendDay = true
              ..isWeekendOvertimeEnabled = true
              ..overtimeType = OvertimeType.WEEKEND_ONLY);
          }

          if ((employee['weekdayOvertime'] as int) > 0) {
            entries.add(TimeSheetEntryModel()
              ..dayDate = DateTime(2024, 1, 1) // Monday
              ..clockInTime = DateTime(2024, 1, 1, 9, 0)
              ..clockOutTime = DateTime(2024, 1, 1, 19, 0) // 10 hours
              ..isWeekendDay = false
              ..hasOvertimeHours = true
              ..overtimeType = OvertimeType.WEEKDAY_ONLY);
          }

          // Save entries for this employee
          await isar.writeTxn(() async {
            await isar.timeSheetEntryModels
                .clear(); // Clear previous employee data
            for (final entry in entries) {
              entry.updateWeekendStatus();
              await isar.timeSheetEntryModels.put(entry);
            }
          });

          // Analyze this employee's timesheet
          final domainEntries = entries.map((e) => e.toDomain()).toList();
          final validationSummary =
              validationOvertimeAnalyzer.analyzeEmployeeTimesheet(
            employeeName: employee['name'] as String,
            month: 1,
            year: 2024,
            entries: domainEntries,
          );

          validationResults.add(validationSummary);
        }

        // Verify results for each employee
        expect(validationResults[0].hasWeekendWork, isTrue);
        expect(validationResults[0].employeeName, equals('Employee A'));

        expect(validationResults[1].hasWeekendWork, isFalse);
        expect(validationResults[1].employeeName, equals('Employee B'));

        expect(validationResults[2].hasWeekendWork, isTrue);
        expect(validationResults[2].employeeName, equals('Employee C'));

        // Verify notifications sent for weekend workers only
        verify(mockNotificationService.notifyWeekendOvertimeDetected(
          'Employee A',
          any,
          any,
        )).called(1);

        verify(mockNotificationService.notifyWeekendOvertimeDetected(
          'Employee C',
          any,
          any,
        )).called(1);

        verifyNever(mockNotificationService.notifyWeekendOvertimeDetected(
          'Employee B',
          any,
          any,
        ));
      });
    });

    group('Validation Edge Cases', () {
      testWidgets('Handle validation with disabled weekend overtime',
          (tester) async {
        const employeeName = 'Test Employee';

        // Create weekend entry with overtime disabled
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = false // Disabled
            ..overtimeType = OvertimeType.NONE,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final validationSummary =
            validationOvertimeAnalyzer.analyzeEmployeeTimesheet(
          employeeName: employeeName,
          month: 1,
          year: 2024,
          entries: domainEntries,
        );

        // Should not flag as weekend overtime when disabled
        expect(validationSummary.hasWeekendWork, isFalse);
        expect(validationSummary.weekendOvertimeHours, equals(Duration.zero));
        expect(validationSummary.weekendWorkAlert, isFalse);
      });

      testWidgets('Handle validation with incomplete time entries',
          (tester) async {
        const employeeName = 'Incomplete Employee';

        // Create entry with missing clock out
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = null // Missing clock out
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final validationSummary =
            validationOvertimeAnalyzer.analyzeEmployeeTimesheet(
          employeeName: employeeName,
          month: 1,
          year: 2024,
          entries: domainEntries,
        );

        // Should handle incomplete entries gracefully
        expect(validationSummary.hasIncompleteEntries, isTrue);
        expect(validationSummary.weekendOvertimeHours, equals(Duration.zero));
        expect(validationSummary.requiresManagerAttention, isTrue);
      });

      testWidgets('Handle validation with excessive weekend hours',
          (tester) async {
        const employeeName = 'Overtime Employee';

        // Create entries with excessive weekend work
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 6, 0) // 6 AM
            ..clockOutTime = DateTime(2024, 1, 6, 22, 0) // 10 PM (16 hours)
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7) // Sunday
            ..clockInTime = DateTime(2024, 1, 7, 6, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 22, 0) // 16 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final validationSummary =
            validationOvertimeAnalyzer.analyzeEmployeeTimesheet(
          employeeName: employeeName,
          month: 1,
          year: 2024,
          entries: domainEntries,
        );

        // Should flag excessive weekend hours
        expect(validationSummary.hasWeekendWork, isTrue);
        expect(validationSummary.weekendOvertimeHours,
            equals(const Duration(hours: 32)));
        expect(validationSummary.hasExcessiveWeekendHours, isTrue);
        expect(validationSummary.requiresManagerAttention, isTrue);
        expect(validationSummary.weekendWorkAlert, isTrue);

        // Should trigger notification for excessive hours
        verify(mockNotificationService.notifyWeekendOvertimeDetected(
          employeeName,
          validationSummary.weekendOvertimeHours,
          validationSummary.weekendDaysWorked,
        )).called(1);
      });
    });

    group('Validation Approval Workflow', () {
      testWidgets('Complete validation approval with weekend hours',
          (tester) async {
        // Requirement 5.3: Include weekend hours in total overtime calculation
        const employeeName = 'Approval Test Employee';

        final entries = <TimeSheetEntryModel>[
          // Weekday overtime
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 2) // Tuesday
            ..clockInTime = DateTime(2024, 1, 2, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 2, 19, 0) // 10 hours
            ..isWeekendDay = false
            ..hasOvertimeHours = true
            ..overtimeType = OvertimeType.WEEKDAY_ONLY,

          // Weekend work
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0) // 8 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final validationSummary =
            validationOvertimeAnalyzer.analyzeEmployeeTimesheet(
          employeeName: employeeName,
          month: 1,
          year: 2024,
          entries: domainEntries,
        );

        // Simulate manager approval
        final approvalData = {
          'employeeName': employeeName,
          'month': 1,
          'year': 2024,
          'weekdayOvertimeHours':
              validationSummary.weekdayOvertimeHours.inMinutes,
          'weekendOvertimeHours':
              validationSummary.weekendOvertimeHours.inMinutes,
          'totalOvertimeHours': validationSummary.totalOvertimeHours.inMinutes,
          'hasWeekendWork': validationSummary.hasWeekendWork,
          'approvedAt': DateTime.now().toIso8601String(),
          'approvedBy': 'Manager Test',
        };

        // Verify approval data includes weekend hours
        expect(approvalData['weekdayOvertimeHours'],
            equals(120)); // 2 hours in minutes
        expect(approvalData['weekendOvertimeHours'],
            equals(480)); // 8 hours in minutes
        expect(
            approvalData['totalOvertimeHours'], equals(600)); // 10 hours total
        expect(approvalData['hasWeekendWork'], isTrue);

        // Verify the validation summary is complete
        expect(validationSummary.isReadyForApproval, isTrue);
        expect(validationSummary.totalOvertimeHours,
            equals(const Duration(hours: 10)));
      });
    });
  });
}
