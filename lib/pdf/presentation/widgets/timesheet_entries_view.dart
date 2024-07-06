import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/timesheet_entry.dart';
import '../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';


class TimesheetEntriesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: Text('Heures enregistrées'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Déclencher un nouveau fetch lorsque l'utilisateur appuie sur le bouton de rafraîchissement
              context.read<TimeSheetListBloc>().add(FindTimesheetEntriesEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<TimeSheetListBloc, TimeSheetListState>(
        builder: (context, state) {
          if (state is TimeSheetListInitial) {
            return Center(child: CircularProgressIndicator());
          } else if (state is TimeSheetListFetchedState) {
            return ListView.builder(
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                return ListTile(
                  title: Text(entry.dayDate),
                  subtitle: Text('${entry.startMorning} - ${entry.endMorning}'),
                  trailing: Text('Durée: ${_calculateDuration(entry)}'),
                );
              },
            );
          } else {
            return Center(child: Text('Une erreur est survenue'));
          }
        },
      ),
    );
  }

  String _calculateDuration(TimesheetEntry entry) {
    final start = DateFormat('HH:mm').parse(entry.startMorning);
    final end = DateFormat('HH:mm').parse(entry.endMorning);
    final duration = end.difference(start);
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }
}