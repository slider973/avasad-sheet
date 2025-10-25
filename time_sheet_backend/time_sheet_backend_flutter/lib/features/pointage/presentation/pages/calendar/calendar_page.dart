import 'package:flutter/material.dart';
import '../../widgets/syncfusion_calendar/syncfusion_timesheet_calendar_widget.dart';

/// Page wrapper for the Syncfusion calendar widget
/// This provides the Scaffold structure while keeping the calendar widget itself clean
class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SyncfusionTimesheetCalendarWidget(),
    );
  }
}
