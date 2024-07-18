import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/timesheet_entry.dart';
import '../../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import '../pointage_widget/pointage_widget.dart';
import 'events.dart';
import 'timesheet_calendar_layout.dart';

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year - 1, kToday.month - 3, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 3, kToday.day);

class TimesheetCalendarWidget extends StatefulWidget {
  const TimesheetCalendarWidget({super.key});

  @override
  _TimesheetCalendarWidgetState createState() => _TimesheetCalendarWidgetState();
}

class _TimesheetCalendarWidgetState extends State<TimesheetCalendarWidget> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final ValueNotifier<List<Event>> _selectedEvents;
  late LinkedHashMap<DateTime, List<Event>> _events;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);
    _events = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _loadEvents() {
    context.read<TimeSheetListBloc>().add(const FindTimesheetEntriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<TimeSheetListBloc, TimeSheetListState>(
        listener: (context, state) {
          if (state is TimeSheetListFetchedState) {
            setState(() {
              _events = _groupEntries(state.entries);
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
            });
          }
        },
        child: TimesheetCalendarLayout(
          firstDay: kFirstDay,
          lastDay: kLastDay,
          focusedDay: _focusedDay,
          selectedDay: _selectedDay,
          calendarFormat: _calendarFormat,
          selectedEvents: _selectedEvents,
          events: _events,
          onDaySelected: _onDaySelected,
          onFormatChanged: _onFormatChanged,
          onPageChanged: _onPageChanged,
          onEventTap: _onEventTap,
          onLoadEvents: _loadEvents,
        ),
      ),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  void _onEventTap(TimesheetEntry entry) {
    final dateFormat = DateFormat('dd-MMM-yy', 'en_US');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Détails du pointage')),
          body: SingleChildScrollView(
            child: PointageWidget(
              entry: entry,
              selectedDate: dateFormat.parse(entry.dayDate),
            ),
          ),
        ),
      ),
    ).then(
          (value) {
        _loadEvents();
      },
    );
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  LinkedHashMap<DateTime, List<Event>> _groupEntries(List<TimesheetEntry> entries) {
    LinkedHashMap<DateTime, List<Event>> map = LinkedHashMap<DateTime, List<Event>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );
    for (var entry in entries) {
      final dateStrToDate = DateFormat("dd-MMM-yy").parse(entry.dayDate);
      final date = DateTime(dateStrToDate.year, dateStrToDate.month, dateStrToDate.day);
      if (map[date] == null) map[date] = [];
      map[date]!.add(Event(entry));
    }
    return map;
  }
}

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}