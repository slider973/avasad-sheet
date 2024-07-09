import 'dart:collection';


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/timesheet_entry.dart';
import '../../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import 'events.dart';

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
      appBar: AppBar(
        title: const Text('Calendrier des pointages'),
      ),
      body: BlocListener<TimeSheetListBloc, TimeSheetListState>(
        listener: (context, state) {
          if (state is TimeSheetListFetchedState) {
            setState(() {
              _events = _groupEntries(state.entries);
              _selectedEvents.value = _getEventsForDay(_selectedDay!);
            });
          }
        },
        child: Column(
          children: [
            TableCalendar<Event>(
              locale: 'fr_FR',
              firstDay: kFirstDay,
              lastDay: kLastDay,
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.teal,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          onTap: () => print('${value[index]}'),
                          title: Text('${value[index]}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
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