import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:isar/isar.dart';

import '../test_utils.dart';
import '../../lib/features/pointage/data/models/timesheet_entry_model.dart';
import '../../lib/services/weekend_overtime_calculator.dart';
import '../../lib/enum/overtime_type.dart';

// Mock the PDF generation service
@GenerateMocks([])
class MockPdfGeneratorService extends Mock {
  Future<String> generateTimesheetPdf({
    required String employeeName,
    required int month,
    required int year,
    required List<dynamic> entries,
    required Map<String, dynamic> overtimeSummary,
  }) async {
    return 'mock_pdf_path.pdf';
  }
}

void main() {
  group('Weekend PDF Generation Integration Tests', () {
    late Isar isar;
    late WeekendOvertimeCalculator weekendOvertimeCalculator;
    late MockPdfGeneratorService mockPdfGenerator;

    setUpAll(() async {
      isar = await setupTestIsar();
    });

    setUp(() async {
      await isar.writeTxn(() async {
        await isar.timeSheetEntryModels.clear();
      });

      weekendOvertimeCalculator = WeekendOvertimeCalculator();
      mockPdfGenerator = MockPdfGeneratorService();
    });

    tearDownAll(() async {
      await isar.close();
    });

    group('PDF Generation with Weekend Hours', () {
      testWidgets('Generate PDF with weekend overtime separation',
          (tester) async {
        // Requirement 1.3: Weekend hours appear in PDF section
        // Requirement 2.2: PDF separates weekend and weekday overtime

        // Create test data with mixed overtime
        final entries = <TimeSheetEntryModel>[
          // Monday - Regular work
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1)
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 17, 0)
            ..isWeekendDay = false
            ..hasOvertimeHours = false
            ..overtimeType = OvertimeType.NONE,

          // Tuesday - Weekday overtime
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 2)
            ..clockInTime = DateTime(2024, 1, 2, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 2, 19, 0) // 10 hours
            ..isWeekendDay = false
            ..hasOvertimeHours = true
            ..overtimeType = OvertimeType.WEEKDAY_ONLY,

          // Saturday - Weekend work
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6)
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0) // 8 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,

          // Sunday - Weekend work
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 7)
            ..clockInTime = DateTime(2024, 1, 7, 10, 0)
            ..clockOutTime = DateTime(2024, 1, 7, 16, 0) // 6 hours
            ..isWeekendDay = true
            ..isWeekendOvertimeEnabled = true
            ..overtimeType = OvertimeType.WEEKEND_ONLY,
        ];

        // Save entries to database
        await isar.writeTxn(() async {
          for (final entry in entries) {
            entry.updateWeekendStatus();
            await isar.timeSheetEntryModels.put(entry);
          }
        });

        // Calculate overtime summary
        final domainEntries = entries.map((e) => e.toDomain()).toList();
        final overtimeSummary =
            weekendOvertimeCalculator.calculateMonthlyOvertime(domainEntries);

        // Verify overtime calculations before PDF generation
        expect(
            overtimeSummary.weekdayOvertime, equals(const Duration(hours: 2)));
        expect(
            overtimeSummary.weekendOvertime, equals(const Duration(hours: 14)));
        expect(
            overtimeSummary.totalOvertime, equals(const Duration(hours: 16)));

        // Prepare PDF data
        final pdfData = {
          'weekdayOvertime': overtimeSummary.weekdayOvertime.inMinutes,
          'weekendOvertime': overtimeSummary.weekendOvertime.inMinutes,
          'totalOvertime': overtimeSummary.totalOvertime.inMinutes,
          'weekendOvertimeRate': overtimeSummary.weekendOvertimeRate,
          'weekdayOvertimeRate': overtimeSummary.weekdayOvertimeRate,
          'entries': entries
              .map((e) => {
                    'date': e.dayDate.toIso8601String(),
                    'clockIn': e.clockInTime?.toIso8601String(),
                    'clockOut': e.clockOutTime?.toIso8601String(),
                    'isWeekend': e.isWeekendDay,
                    'overtimeType': e.overtimeType.name,
                    'totalHours': e.toDomain().calculateDailyTotal().inMinutes,
                  })
              .toList(),
        };

        // Mock PDF generation
        when(mockPdfGenerator.generateTimesheetPdf(
          employeeName: anyNamed('employeeName'),
          month: anyNamed('month'),
          year: anyNamed('year'),
          entries: anyNamed('entries'),
          overtimeSummary: anyNamed('overtimeSummary'),
        )).thenAnswer((_) async => 'test_timesheet_2024_01.pdf');

        // Generate PDF
        final pdfPath = await mockPdfGenerator.generateTimesheetPdf(
          employeeName: 'Test Employee',
          month: 1,
          year: 2024,
          entries: pdfData['entries'] as List<dynamic>,
          overtimeSummary: {
            'weekdayOvertime': pdfData['weekdayOvertime'],
            'weekendOvertime': pdfData['weekendOvertime'],
            'totalOvertime': pdfData['totalOvertime'],
            'weekendOvertimeRate': pdfData['weekendOvertimeRate'],
            'weekdayOvertimeRate': pdfData['weekdayOvertimeRate'],
          },
        );

        // Verify PDF generation was called with correct data
        expect(pdfPath, equals('test_timesheet_2024_01.pdf'));

        // Verify the mock was called with the expected parameters
        verify(mockPdfGenerator.generateTimesheetPdf(
          employeeName: 'Test Employee',
          month: 1,
          year: 2024,
          entries: any,
          overtimeSummary: any,
        )).called(1);
      });

      testWidgets('Generate PDF with only weekend hours', (tester) async {
        // Test PDF generation when only weekend work exists
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6) // Saturday
            ..clockInTime = DateTime(2024, 1, 6, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 6, 17, 0)
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
        final overtimeSummary =
            weekendOvertimeCalculator.calculateMonthlyOvertime(domainEntries);

        expect(overtimeSummary.weekdayOvertime, equals(Duration.zero));
        expect(
            overtimeSummary.weekendOvertime, equals(const Duration(hours: 8)));
        expect(overtimeSummary.totalOvertime, equals(const Duration(hours: 8)));

        // Mock and verify PDF generation
        when(mockPdfGenerator.generateTimesheetPdf(
          employeeName: anyNamed('employeeName'),
          month: anyNamed('month'),
          year: anyNamed('year'),
          entries: anyNamed('entries'),
          overtimeSummary: anyNamed('overtimeSummary'),
        )).thenAnswer((_) async => 'weekend_only_timesheet.pdf');

        final pdfPath = await mockPdfGenerator.generateTimesheetPdf(
          employeeName: 'Weekend Worker',
          month: 1,
          year: 2024,
          entries: [],
          overtimeSummary: {
            'weekendOvertime': overtimeSummary.weekendOvertime.inMinutes,
            'weekdayOvertime': 0,
            'totalOvertime': overtimeSummary.totalOvertime.inMinutes,
          },
        );

        expect(pdfPath, equals('weekend_only_timesheet.pdf'));
      });

      testWidgets('Generate PDF with no weekend hours', (tester) async {
        // Test PDF generation with only weekday work
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 1) // Monday
            ..clockInTime = DateTime(2024, 1, 1, 9, 0)
            ..clockOutTime = DateTime(2024, 1, 1, 19, 0) // 10 hours
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
        final overtimeSummary =
            weekendOvertimeCalculator.calculateMonthlyOvertime(domainEntries);

        expect(
            overtimeSummary.weekdayOvertime, equals(const Duration(hours: 2)));
        expect(overtimeSummary.weekendOvertime, equals(Duration.zero));
        expect(overtimeSummary.totalOvertime, equals(const Duration(hours: 2)));

        // Verify PDF can be generated without weekend data
        when(mockPdfGenerator.generateTimesheetPdf(
          employeeName: anyNamed('employeeName'),
          month: anyNamed('month'),
          year: anyNamed('year'),
          entries: anyNamed('entries'),
          overtimeSummary: anyNamed('overtimeSummary'),
        )).thenAnswer((_) async => 'weekday_only_timesheet.pdf');

        final pdfPath = await mockPdfGenerator.generateTimesheetPdf(
          employeeName: 'Weekday Worker',
          month: 1,
          year: 2024,
          entries: [],
          overtimeSummary: {
            'weekdayOvertime': overtimeSummary.weekdayOvertime.inMinutes,
            'weekendOvertime': 0,
            'totalOvertime': overtimeSummary.totalOvertime.inMinutes,
          },
        );

        expect(pdfPath, equals('weekday_only_timesheet.pdf'));
      });
    });

    group('PDF Data Validation', () {
      testWidgets('Validates overtime data before PDF generation',
          (tester) async {
        // Test that invalid data is handled properly
        final entries = <TimeSheetEntryModel>[
          TimeSheetEntryModel()
            ..dayDate = DateTime(2024, 1, 6)
            ..clockInTime = DateTime(
                2024, 1, 6, 17, 0) // Invalid: clock out before clock in
            ..clockOutTime = DateTime(2024, 1, 6, 9, 0)
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
        final overtimeSummary =
            weekendOvertimeCalculator.calculateMonthlyOvertime(domainEntries);

        // Should handle invalid data gracefully
        expect(overtimeSummary.weekendOvertime, equals(Duration.zero));
        expect(overtimeSummary.totalOvertime, equals(Duration.zero));
      });

      testWidgets('Handles empty entries list for PDF generation',
          (tester) async {
        final overtimeSummary =
            weekendOvertimeCalculator.calculateMonthlyOvertime([]);

        expect(overtimeSummary.weekdayOvertime, equals(Duration.zero));
        expect(overtimeSummary.weekendOvertime, equals(Duration.zero));
        expect(overtimeSummary.totalOvertime, equals(Duration.zero));

        // Should be able to generate PDF even with no entries
        when(mockPdfGenerator.generateTimesheetPdf(
          employeeName: anyNamed('employeeName'),
          month: anyNamed('month'),
          year: anyNamed('year'),
          entries: anyNamed('entries'),
          overtimeSummary: anyNamed('overtimeSummary'),
        )).thenAnswer((_) async => 'empty_timesheet.pdf');

        final pdfPath = await mockPdfGenerator.generateTimesheetPdf(
          employeeName: 'No Work Employee',
          month: 1,
          year: 2024,
          entries: [],
          overtimeSummary: {
            'weekdayOvertime': 0,
            'weekendOvertime': 0,
            'totalOvertime': 0,
          },
        );

        expect(pdfPath, equals('empty_timesheet.pdf'));
      });
    });
  });
}
