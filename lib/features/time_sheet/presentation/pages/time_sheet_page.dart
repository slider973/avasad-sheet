import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/adaptive_boutton.dart';
import '../widgets/watch_counter/_buildTimer.dart';
import '../widgets/watch_counter/countrer.dart';
import '../widgets/days_pointed_list.dart';
import '../widgets/timesheet_display_widget/timesheet_display_widget.dart';
import 'time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

class TimeSheetPage extends StatelessWidget {
  const TimeSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time sheet')),
      backgroundColor: Colors.teal[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            PointageWidget(),
          ],
        ),
      ),
    );
  }
}

class SecondLineButton extends StatelessWidget {
  const SecondLineButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AdaptiveButton(
          onPressed: () {
            DateTime now = DateTime.now();
            context.read<TimeSheetBloc>().add(TimeSheetStartBreakEvent(now));
          },
          text: 'Début pause',
        ),
        AdaptiveButton(
          onPressed: () {
            DateTime now = DateTime.now();
            context.read<TimeSheetBloc>().add(TimeSheetEndBreakEvent(now));
          },
          text: 'Fin pause',
        ),
      ],
    );
  }
}

class FirstLineButton extends StatelessWidget {
  const FirstLineButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AdaptiveButton(
          onPressed: () {
            // Obtenez l'heure actuelle ou les données pertinentes pour TimesheetEntry
            DateTime now = DateTime.now();
            context.read<TimeSheetBloc>().add(TimeSheetEnterEvent(now));
          },
          text: 'Entrer',
        ),
        AdaptiveButton(
          onPressed: () {
            DateTime now = DateTime.now();
            context.read<TimeSheetBloc>().add(TimeSheetOutEvent(now));
          },
          text: 'Sortir',
        ),
      ],
    );
  }
}
