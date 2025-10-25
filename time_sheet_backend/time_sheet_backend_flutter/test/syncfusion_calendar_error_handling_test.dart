import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/calendar_error_handler.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/timesheet_appointment_data_source.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

// Generate mocks
@GenerateMocks([])
void main() {
  group('Calendar Error Handling Tests', () {
    late Widget testApp;

    setUp(() {
      testApp = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Container(),
          ),
        ),
      );
    });

    testWidgets('CalendarErrorHandler handles data loading errors correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      final context = tester.element(find.byType(Container));

      // Test data loading error handling
      CalendarErrorHandler.handleDataLoadingError(
        context,
        Exception('Test error'),
        StackTrace.current,
        customMessage: 'Test error message',
      );

      await tester.pump();

      // Verify that a SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('CalendarErrorHandler handles navigation errors correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      final context = tester.element(find.byType(Container));

      // Test navigation error handling
      CalendarErrorHandler.handleNavigationError(
        context,
        'test page',
        StateError('Navigator not available'),
        StackTrace.current,
      );

      await tester.pump();

      // Verify that a SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Navigation non disponible'), findsOneWidget);
    });

    testWidgets('CalendarErrorHandler handles appointment errors correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      final context = tester.element(find.byType(Container));

      // Test appointment error handling
      CalendarErrorHandler.handleAppointmentError(
        context,
        'test-entry-id',
        ArgumentError('Invalid appointment data'),
        StackTrace.current,
      );

      await tester.pump();

      // Verify that a SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
          find.textContaining('Données d\'entrée invalides'), findsOneWidget);
    });

    testWidgets('CalendarErrorHandler handles interaction errors correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      final context = tester.element(find.byType(Container));

      // Test interaction error handling
      CalendarErrorHandler.handleInteractionError(
        context,
        'calendar tap',
        TypeError(),
        StackTrace.current,
      );

      await tester.pump();

      // Verify that a SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
          find.textContaining('Type d\'élément non supporté'), findsOneWidget);
    });

    testWidgets('CalendarErrorHandler handles validation errors correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(testApp);

      final context = tester.element(find.byType(Container));

      // Test validation error handling
      CalendarErrorHandler.handleValidationError(
        context,
        'date field',
        'Date format is invalid',
      );

      await tester.pump();

      // Verify that a SnackBar is shown with warning color
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Erreur de validation'), findsOneWidget);
    });

    test('CalendarErrorHandler validates date parsing correctly', () {
      // Test valid date parsing
      expect(
        () => CalendarErrorHandler.validateAndParseDate('01-Jan-24', 'test-id'),
        returnsNormally,
      );

      // Test invalid date parsing
      expect(
        () => CalendarErrorHandler.validateAndParseDate(
            'invalid-date', 'test-id'),
        throwsA(isA<FormatException>()),
      );

      // Test empty date string
      expect(
        () => CalendarErrorHandler.validateAndParseDate('', 'test-id'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('TimesheetAppointmentDataSource handles invalid entries gracefully',
        () {
      // Create a list with valid and invalid entries
      final entries = <TimesheetEntry>[
        TimesheetEntry(
          id: 1,
          dayDate: '01-Jan-24',
          dayOfWeekDate: 'Monday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absence: null,
          absenceReason: null,
          period: null,
        ),
        TimesheetEntry(
          id: 2,
          dayDate: '', // Invalid empty date
          dayOfWeekDate: 'Tuesday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absence: null,
          absenceReason: null,
          period: null,
        ),
        TimesheetEntry(
          id: 3,
          dayDate: 'invalid-date-format', // Invalid date format
          dayOfWeekDate: 'Wednesday',
          startMorning: '09:00',
          endMorning: '12:00',
          startAfternoon: '13:00',
          endAfternoon: '17:00',
          absence: null,
          absenceReason: null,
          period: null,
        ),
      ];

      // Create data source - should not throw even with invalid entries
      expect(
        () => TimesheetAppointmentDataSource.fromTimesheetEntries(entries),
        returnsNormally,
      );

      final dataSource =
          TimesheetAppointmentDataSource.fromTimesheetEntries(entries);

      // Should only have appointments for valid entries
      expect(dataSource.appointments?.length, equals(1));
    });

    test('CalendarException provides proper error information', () {
      const exception = CalendarException(
        'Test error message',
        operation: 'test operation',
        originalError: 'original error',
      );

      expect(exception.message, equals('Test error message'));
      expect(exception.operation, equals('test operation'));
      expect(exception.originalError, equals('original error'));
      expect(exception.toString(), contains('Test error message'));
      expect(exception.toString(), contains('test operation'));
      expect(exception.toString(), contains('original error'));
    });

    test('TimeoutException provides proper timeout information', () {
      const timeout = Duration(seconds: 30);
      const exception = TimeoutException('Operation timed out', timeout);

      expect(exception.message, equals('Operation timed out'));
      expect(exception.timeout, equals(timeout));
      expect(exception.toString(), contains('Operation timed out'));
      expect(exception.toString(), contains('30s'));
    });
  });
}
