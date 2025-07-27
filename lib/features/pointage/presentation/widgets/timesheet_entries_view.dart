import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/timesheet_entry.dart';
import '../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import 'timesheet_entry_card.dart';


class TimesheetEntriesWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Heures enregistrées'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Déclencher un nouveau fetch lorsque l'utilisateur appuie sur le bouton de rafraîchissement
              context.read<TimeSheetListBloc>().add(const FindTimesheetEntriesEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<TimeSheetListBloc, TimeSheetListState>(
        builder: (context, state) {
          if (state is TimeSheetListInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TimeSheetListFetchedState) {
            return ListView.builder(
              itemCount: state.entries.length,
              itemBuilder: (context, index) {
                final entry = state.entries[index];
                return TimesheetEntryCard(
                  entry: entry,
                  onRefresh: () {
                    context.read<TimeSheetListBloc>().add(const FindTimesheetEntriesEvent());
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('Une erreur est survenue'));
          }
        },
      ),
    );
  }
}