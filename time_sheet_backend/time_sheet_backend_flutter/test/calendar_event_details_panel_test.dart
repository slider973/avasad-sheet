import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/calendar_event_details_panel.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/syncfusion_calendar/timesheet_appointment.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/enum/absence_period.dart';

void main() {
  setUpAll(() async {
    // Initialize date formatting for tests
    await initializeDateFormatting('fr_FR', null);
  });

  group('CalendarEventDetailsPanel', () {
    late DateTime testDate;
    late List<TimesheetAppointment> testAppointments;
    late TimesheetEntry mockWorkEntry;
    late TimesheetEntry mockAbsenceEntry;

    setUp(() {
      testDate = DateTime(2024, 1, 15);

      // Create mock timesheet entries
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

      mockAbsenceEntry = TimesheetEntry(
        id: 2,
        dayDate: DateFormat('dd-MMM-yy', 'en_US').format(testDate),
        dayOfWeekDate: DateFormat('EEEE').format(testDate),
        startMorning: '',
        endMorning: '',
        startAfternoon: '',
        endAfternoon: '',
        hasOvertimeHours: false,
        absenceReason: 'Congé maladie',
        period: AbsencePeriod.fullDay.value,
      );

      testAppointments = [
        TimesheetAppointment.fromWorkEntry(
          entry: mockWorkEntry,
          date: testDate,
        ),
        TimesheetAppointment.fromAbsenceEntry(
          entry: mockAbsenceEntry,
          date: testDate,
          absencePeriod: AbsencePeriod.fullDay,
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
        locale: const Locale('en', 'US'), // Use English locale for tests
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

    testWidgets('displays header with correct date and event count',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check if header is displayed
      expect(find.byIcon(Icons.event), findsOneWidget);

      // Check if date is formatted correctly (should contain the date)
      expect(find.textContaining('15'), findsOneWidget);
      expect(find.textContaining('2 événements'), findsOneWidget);
    });

    testWidgets('displays empty state when no appointments', (tester) async {
      await tester.pumpWidget(createTestWidget(appointments: []));

      // Check empty state elements
      expect(find.byIcon(Icons.event_available), findsOneWidget);
      expect(find.text('Aucun événement'), findsOneWidget);
      expect(find.text('Aucune entrée de pointage pour cette date'),
          findsOneWidget);
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

      // Check if appointments are displayed
      expect(find.text('Travail 8h'), findsOneWidget);
      expect(find.text('Absence - Congé maladie'), findsOneWidget);

      // Check if work and absence icons are present
      expect(find.byIcon(Icons.work), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('displays work appointment metadata correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for work duration metadata
      expect(find.text('8h'), findsOneWidget);

      // Check for work icon
      expect(find.byIcon(Icons.work), findsOneWidget);
    });

    testWidgets('displays absence appointment metadata correctly',
        (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for absence period metadata
      expect(find.text(AbsencePeriod.fullDay.value), findsOneWidget);

      // Check for absence icon
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('handles event tap correctly', (tester) async {
      TimesheetEntry? tappedEntry;

      await tester.pumpWidget(createTestWidget(
        onEventTap: (entry) => tappedEntry = entry,
      ));

      // Tap on the first appointment (work entry)
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

    testWidgets('displays weekend work metadata', (tester) async {
      final weekendEntry = TimesheetEntry(
        id: 3,
        dayDate: DateFormat('dd-MMM-yy', 'en_US').format(testDate),
        dayOfWeekDate: DateFormat('EEEE').format(testDate),
        startMorning: '08:00',
        endMorning: '12:00',
        startAfternoon: '',
        endAfternoon: '',
        hasOvertimeHours: false,
        isWeekendDay: true,
      );

      final weekendAppointment = TimesheetAppointment.fromWorkEntry(
        entry: weekendEntry,
        date: testDate,
      );

      await tester.pumpWidget(createTestWidget(
        appointments: [weekendAppointment],
      ));

      // Check for weekend metadata
      expect(find.text('Week-end'), findsOneWidget);
    });

    testWidgets('displays overtime metadata', (tester) async {
      final overtimeEntry = TimesheetEntry(
        id: 4,
        dayDate: DateFormat('dd-MMM-yy', 'en_US').format(testDate),
        dayOfWeekDate: DateFormat('EEEE').format(testDate),
        startMorning: '08:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '18:00',
        hasOvertimeHours: true,
      );

      final overtimeAppointment = TimesheetAppointment.fromWorkEntry(
        entry: overtimeEntry,
        date: testDate,
      );

      await tester.pumpWidget(createTestWidget(
        appointments: [overtimeAppointment],
      ));

      // Check for overtime metadata
      expect(find.text('Heures sup.'), findsOneWidget);
    });

    testWidgets('displays half-day absence correctly', (tester) async {
      final halfDayEntry = TimesheetEntry(
        id: 5,
        dayDate: DateFormat('dd-MMM-yy', 'en_US').format(testDate),
        dayOfWeekDate: DateFormat('EEEE').format(testDate),
        startMorning: '08:00',
        endMorning: '12:00',
        startAfternoon: '',
        endAfternoon: '',
        hasOvertimeHours: false,
        absenceReason: 'Rendez-vous médical',
        period: AbsencePeriod.halfDay.value,
      );

      final halfDayAppointment = TimesheetAppointment.fromAbsenceEntry(
        entry: halfDayEntry,
        date: testDate,
        absencePeriod: AbsencePeriod.halfDay,
      );

      await tester.pumpWidget(createTestWidget(
        appointments: [halfDayAppointment],
      ));

      // Check for half-day absence
      expect(find.text('Absence ½j - Rendez-vous...'), findsOneWidget);
      expect(find.text(AbsencePeriod.halfDay.value), findsOneWidget);
    });

    testWidgets('handles long appointment subjects correctly', (tester) async {
      final longSubjectEntry = TimesheetEntry(
        id: 6,
        dayDate: DateFormat('dd-MMM-yy', 'en_US').format(testDate),
        dayOfWeekDate: DateFormat('EEEE').format(testDate),
        startMorning: '',
        endMorning: '',
        startAfternoon: '',
        endAfternoon: '',
        hasOvertimeHours: false,
        absenceReason: 'Congé maladie pour traitement médical de longue durée',
        period: AbsencePeriod.fullDay.value,
      );

      final longSubjectAppointment = TimesheetAppointment.fromAbsenceEntry(
        entry: longSubjectEntry,
        date: testDate,
        absencePeriod: AbsencePeriod.fullDay,
      );

      await tester.pumpWidget(createTestWidget(
        appointments: [longSubjectAppointment],
      ));

      // Check that long subject is truncated
      expect(find.textContaining('Congé maladie...'), findsOneWidget);
    });

    testWidgets('displays correct event count in header', (tester) async {
      // Test with single appointment
      await tester.pumpWidget(createTestWidget(
        appointments: [testAppointments.first],
      ));

      expect(find.textContaining('1 événement'), findsOneWidget);

      // Test with multiple appointments
      await tester.pumpWidget(createTestWidget(
        appointments: testAppointments,
      ));

      expect(find.textContaining('2 événements'), findsOneWidget);
    });

    testWidgets('displays visual indicators correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for colored indicators (containers with specific colors)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Check for chevron icons
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });
  });
}
