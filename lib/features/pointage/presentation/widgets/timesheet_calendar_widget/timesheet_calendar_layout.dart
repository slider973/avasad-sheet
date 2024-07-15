import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'timesheet_calendar_header.dart';
import 'timesheet_calendar_body.dart';
import 'timesheet_event_list.dart';
import '../../../domain/entities/timesheet_entry.dart';
import 'events.dart';

class TimesheetCalendarLayout extends StatelessWidget {
  final DateTime firstDay;
  final DateTime lastDay;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final CalendarFormat calendarFormat;
  final ValueNotifier<List<Event>> selectedEvents;
  final LinkedHashMap<DateTime, List<Event>> events;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;
  final Function(TimesheetEntry) onEventTap;
  final Function() onLoadEvents;

  const TimesheetCalendarLayout({
    Key? key,
    required this.firstDay,
    required this.lastDay,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.selectedEvents,
    required this.events,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
    required this.onEventTap,
    required this.onLoadEvents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TimesheetCalendarHeader(title: 'Calendrier des pointages'),
        TimesheetCalendarBody(
          firstDay: firstDay,
          lastDay: lastDay,
          focusedDay: focusedDay,
          selectedDay: selectedDay,
          calendarFormat: calendarFormat,
          events: events,
          onDaySelected: onDaySelected,
          onFormatChanged: onFormatChanged,
          onPageChanged: onPageChanged,
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: TimesheetEventList(
            selectedEvents: selectedEvents,
            onEventTap: onEventTap,
            selectedDay: selectedDay ?? DateTime.now(),
            onEventsUpdated: onLoadEvents,
          ),
        ),
      ],
    );
  }
}
