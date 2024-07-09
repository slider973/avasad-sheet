import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';


class DaysPointedListWidget extends StatelessWidget {
  const DaysPointedListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeSheetListBloc, TimeSheetListState>(
      builder: (context, state) {
        if (state is TimeSheetListFetchedState) {
          return ListView.builder(
            itemCount: state.entries.length,
            itemBuilder: (context, index) {
              final entry = state.entries[index];
              return ListTile(
                title: Text("${entry.dayDate} - ${entry.dayOfWeekDate}"),
                subtitle: Text("Matin: ${entry.startMorning} - ${entry.endMorning}, Après-midi: ${entry.startAfternoon} - ${entry.endAfternoon}"),
              );
            },
          );
        }
        context.read<TimeSheetListBloc>().add(const FindTimesheetEntriesEvent());
        return const Center(child: Text('Chargement...'));
      },
    );
  }
}