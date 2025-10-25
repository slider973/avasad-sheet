import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/syncfusion_timesheet_calendar_widget.dart';
import 'package:time_sheet/features/pointage/presentation/pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import 'package:time_sheet/features/pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

// Simple mock classes for testing
class MockTimeSheetListBloc extends TimeSheetListBloc {
  MockTimeSheetListBloc() : super();

  @override
  Stream<TimeSheetListState> get stream =>
      Stream.fromIterable([const TimeSheetListInitial()]);

  @override
  TimeSheetListState get state => const TimeSheetListInitial();

  @override
  void add(TimeSheetListEvent event) {
    // Mock implementation - do nothing
  }
}

class MockTimeSheetBloc extends TimeSheetBloc {
  MockTimeSheetBloc() : super();

  @override
  Stream<TimeSheetState> get stream =>
      Stream.fromIterable([TimeSheetInitial()]);

  @override
  TimeSheetState get state => TimeSheetInitial();

  @override
  void add(TimeSheetEvent event) {
    // Mock implementation - do nothing
  }
}

void main() {
  group('SyncfusionTimesheetCalendarWidget Interaction Tests', () {
    late MockTimeSheetListBloc mockTimeSheetListBloc;
    late MockTimeSheetBloc mockTimeSheetBloc;

    setUp(() {
      mockTimeSheetListBloc = MockTimeSheetListBloc();
      mockTimeSheetBloc = MockTimeSheetBloc();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<TimeSheetListBloc>.value(value: mockTimeSheetListBloc),
            BlocProvider<TimeSheetBloc>.value(value: mockTimeSheetBloc),
          ],
          child: const SyncfusionTimesheetCalendarWidget(),
        ),
      );
    }

    testWidgets('should display calendar with proper configuration',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SfCalendar), findsOneWidget);
      expect(find.text('Calendrier des pointages'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should handle calendar tap on date cell',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap on calendar (this will trigger onTap handler)
      final calendarFinder = find.byType(SfCalendar);
      expect(calendarFinder, findsOneWidget);

      await tester.tap(calendarFinder);
      await tester.pumpAndSettle();

      // Assert - Calendar should still be present after tap
      expect(find.byType(SfCalendar), findsOneWidget);
    });

    testWidgets('should handle refresh button tap',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Assert - Calendar should still be present after refresh
      expect(find.byType(SfCalendar), findsOneWidget);
    });

    testWidgets('should display loading state correctly',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show loading initially when no data
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement du calendrier...'), findsOneWidget);
    });

    group('Calendar Interaction Handlers', () {
      testWidgets('onTap handler should be properly configured',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act & Assert
        final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
        expect(calendar.onTap, isNotNull);
      });

      testWidgets('onSelectionChanged handler should be properly configured',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act & Assert
        final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
        expect(calendar.onSelectionChanged, isNotNull);
      });

      testWidgets('onViewChanged handler should be properly configured',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Act & Assert
        final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
        expect(calendar.onViewChanged, isNotNull);
      });
    });

    group('Navigation Tests', () {
      testWidgets('should have proper calendar configuration for navigation',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
        expect(calendar.allowViewNavigation, isTrue);
        expect(calendar.allowedViews, contains(CalendarView.month));
        expect(calendar.allowedViews, contains(CalendarView.week));
        expect(calendar.allowedViews, contains(CalendarView.workWeek));
      });

      testWidgets('should have proper date range configuration',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
        expect(calendar.minDate, isNotNull);
        expect(calendar.maxDate, isNotNull);

        // Verify date range (1 year back, 3 months forward)
        final now = DateTime.now();
        final expectedMinDate = DateTime(now.year - 1, now.month, now.day);
        final expectedMaxDate = DateTime(now.year, now.month + 3, now.day);

        expect(calendar.minDate!.year, expectedMinDate.year);
        expect(calendar.maxDate!.year, expectedMaxDate.year);
      });
    });

    group('Event Handlers Verification', () {
      testWidgets('should have all required event handlers configured',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));

        // Verify all interaction handlers are present
        expect(calendar.onTap, isNotNull,
            reason: 'onTap handler should be configured');
        expect(calendar.onSelectionChanged, isNotNull,
            reason: 'onSelectionChanged handler should be configured');
        expect(calendar.onViewChanged, isNotNull,
            reason: 'onViewChanged handler should be configured');

        // Verify calendar configuration supports interactions
        expect(calendar.view, equals(CalendarView.month),
            reason: 'Should default to month view');
        expect(calendar.controller, isNotNull,
            reason: 'Calendar controller should be configured');
      });

      testWidgets('should have proper appointment builder configured',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Assert
        final calendar = tester.widget<SfCalendar>(find.byType(SfCalendar));
        expect(calendar.appointmentBuilder, isNotNull,
            reason:
                'Appointment builder should be configured for custom styling');
      });
    });
  });
}
