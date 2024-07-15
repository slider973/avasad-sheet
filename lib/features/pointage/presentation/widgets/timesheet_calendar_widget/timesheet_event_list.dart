import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/timesheet_entry.dart';
import '../../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import 'events.dart';
import '../pointage_widget/pointage_widget.dart';

class TimesheetEventList extends StatelessWidget {
  final ValueNotifier<List<Event>> selectedEvents;
  final Function(TimesheetEntry) onEventTap;
  final DateTime selectedDay;
  final VoidCallback onEventsUpdated;

  const TimesheetEventList({
    Key? key,
    required this.selectedEvents,
    required this.onEventTap,
    required this.selectedDay,
    required this.onEventsUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Event>>(
      valueListenable: selectedEvents,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return _buildCreatePointageButton(context);
        }
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
                onTap: () => onEventTap(value[index].entry),
                title: Text('${value[index]}'),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCreatePointageButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => _createNewPointage(context),
        child: const Text('Créer un pointage pour ce jour'),
      ),
    );
  }

  void _createNewPointage(BuildContext context) {
    final dateFormat = DateFormat('dd-MMM-yy', 'en_US');
    final formattedDate = dateFormat.format(selectedDay);

    // Créer une nouvelle entrée TimesheetEntry
    final newEntry = TimesheetEntry(
      dayDate: formattedDate,
      dayOfWeekDate: DateFormat.EEEE().format(selectedDay),
      startMorning: '',
      endMorning: '',
      startAfternoon: '',
      endAfternoon: '',
    );

    // Mettre à jour l'état du bloc avec la nouvelle entrée
    context.read<TimeSheetBloc>().add(UpdateTimeSheetDataEvent(newEntry));

    // Naviguer vers le PointageWidget
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Nouveau pointage')),
          body: PointageWidget(
            entry: newEntry,
            selectedDate: selectedDay,
          ),
        ),
      ),
    )
        .then(
      (value) {
        onEventsUpdated();
      },
    );
  }
}
