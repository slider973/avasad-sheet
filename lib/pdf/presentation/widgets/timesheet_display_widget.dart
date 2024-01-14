import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../domain/entities/timesheet_entry.dart';
import '../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';


class TimesheetDisplayWidget extends StatelessWidget {
  const TimesheetDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeSheetBloc, TimeSheetState>(
      builder: (context, state) {
        if (state is TimeSheetDataState) {
          // Affichage des informations lorsque l'état est TimeSheetDataState
          return _buildTimesheetInfo(state.entry);
        } else if (state is TimeSheetInitial) {
          // Affichage par défaut lorsque l'état est initial
          return const Text('Aucune donnée de feuille de temps disponible.');
        } else {
          // Gestion des autres états si nécessaire
          return const Text('État non pris en charge.');
        }
      },
    );
  }

  Widget _buildTimesheetInfo(TimesheetEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Date: ${entry.dayDate}'),
        Text('Jour de la semaine: ${entry.dayOfWeekDate}'),
        Text('Début Matinée: ${entry.startMorning}'),
        Text('Fin Matinée: ${entry.endMorning}'),
        Text('Début Après-Midi: ${entry.startAfternoon}'),
        Text('Fin Après-Midi: ${entry.endAfternoon}'),
      ],
    );
  }
}
