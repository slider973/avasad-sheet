import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/calendar_event_details_panel.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/timesheet_appointment.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/enum/absence_period.dart';

void main() {
  group('CalendarEventDetailsPanel', () {
    late DateTime testDate;
    late List<TimesheetAppointment> testAppointments;
    late TimesheetEntry mockWorkEntry;

    setUp(() {
      testDate = DateTime(2024, 1, 15);

      // Create mock timesheet entry
      mockWorkEntry = TimesheetEntry(
        id: 1,
        dayDate: DateFormat('dd-MMM-yy', 'en_US').format(testDate),
        dayOfWeekDate: DateFormat('EEEE').format(testDate),
        startMorning: '08:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '17:00',
        hasOvertimeHours: false,
      );

      testAppointments = [
        TimesheetAppointment.fromWorkEntry(
          entry: mockWorkEntry,
          date: testDate,
        ),
      ];
    });

    Widget createTestWidget({
      List<TimesheetAppointment>? appointments,
      Function(TimesheetEntry)? onEventTap,
      VoidCallback? onAddEntry,
      bool showAddButton = true,
    }) {
      return MaterialApp(
        locale: const Locale('en', 'US'),
        home: Scaffold(
          body: CalendarEventDetailsPanel(
            selectedDate: testDate,
            appointments: appointments ?? testAppointments,
            onEventTap: onEventTap ?? (entry) {},
            onAddEntry: onAddEntry,
            showAddButton: showAddButton,
          ),
        ),
      );
    }

    testWidgets('displays header with event icon', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check if header is displayed
      expect(find.byIcon(Icons.event), findsOneWidget);
    });

    testWidgets('displays empty state when no appointments', (tester) async {
      await tester.pumpWidget(createTestWidget(appointments: []));

      // Check empty state elements
      expect(find.byIcon(Icons.event_available), findsOneWidget);
      expect(find.text('Aucun événement'), findsOneWidget);
    });

    testWidgets('displays add button in empty state when enabled',
        (tester) async {
      bool addButtonTapped = false;

      await tester.pumpWidget(createTestWidget(
        appointments: [],
        onAddEntry: () => addButtonTapped = true,
        showAddButton: true,
      ));

      // Check if add button is present
      expect(find.text('Créer une entrée'), findsOneWidget);

      // Tap the add button
      await tester.tap(find.text('Créer une entrée'));
      await tester.pump();

      expect(addButtonTapped, isTrue);
    });

    testWidgets('does not display add button when disabled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        appointments: [],
        showAddButton: false,
      ));

      // Check that add button is not present
      expect(find.text('Créer une entrée'), findsNothing);
      expect(find.text('Ajouter'), findsNothing);
    });

    testWidgets('displays list of appointments correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check if work appointment is displayed
      expect(find.text('Travail 8h'), findsOneWidget);

      // Check if work icon is present
      expect(find.byIcon(Icons.work), findsOneWidget);
    });

    testWidgets('handles event tap correctly', (tester) async {
      TimesheetEntry? tappedEntry;

      await tester.pumpWidget(createTestWidget(
        onEventTap: (entry) => tappedEntry = entry,
      ));

      // Tap on the appointment
      await tester.tap(find.text('Travail 8h'));
      await tester.pump();

      expect(tappedEntry, isNotNull);
      expect(tappedEntry!.id, equals(1));
    });

    testWidgets('displays add button in header when enabled', (tester) async {
      bool addButtonTapped = false;

      await tester.pumpWidget(createTestWidget(
        onAddEntry: () => addButtonTapped = true,
        showAddButton: true,
      ));

      // Check if header add button is present
      expect(find.text('Ajouter'), findsOneWidget);

      // Tap the header add button
      await tester.tap(find.text('Ajouter'));
      await tester.pump();

      expect(addButtonTapped, isTrue);
    });

    testWidgets('displays work appointment with correct duration',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for work duration metadata (8 hours)
      expect(find.text('8h'), findsOneWidget);
    });

    testWidgets('displays chevron icons for navigation', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for chevron icons
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('widget builds without errors', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify the widget builds successfully
      expect(find.byType(CalendarEventDetailsPanel), findsOneWidget);
    });
  });
}
