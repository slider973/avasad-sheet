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
            final event = value[index];
            return _buildEventCard(context, event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    Color cardColor;
    IconData eventIcon;
    String eventTitle;

    if (event.entry.startMorning.isEmpty && event.entry.endMorning.isEmpty &&
        event.entry.startAfternoon.isEmpty && event.entry.endAfternoon.isEmpty) {
      cardColor = Colors.orange.shade100.withOpacity(0.7);
      eventIcon = Icons.event_busy;
      eventTitle = "Absence";
    } else {
      cardColor = Colors.teal.shade200.withOpacity(0.3);
      eventIcon = Icons.work;
      eventTitle = "Journée de travail";
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: InkWell(
        onTap: () => onEventTap(event.entry),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(eventIcon, color: Colors.black87, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    eventTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatTimeRange(event.entry),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),

            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRange(TimesheetEntry entry) {
    if (entry.startMorning.isNotEmpty && entry.endAfternoon.isNotEmpty) {
      return "${entry.startMorning} - ${entry.endAfternoon}";
    } else {
      return "Pas de travail";
    }
  }

  Widget _buildAvatars() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey.shade300,
          child: Icon(Icons.person, size: 16, color: Colors.grey.shade700),
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey.shade300,
          child: Icon(Icons.person, size: 16, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildCreatePointageButton(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Créer un pointage'),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: () => _createNewPointage(context),
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
