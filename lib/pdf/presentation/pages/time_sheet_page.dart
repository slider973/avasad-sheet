import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/pdf/presentation/pages/time-sheet/bloc/time_sheet_bloc.dart';

import '../../../services/logger_service.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../widgets/adaptive_boutton.dart';
import '../widgets/countrer.dart';
import '../widgets/timesheet_display_widget.dart';

class TimeSheetPage extends StatelessWidget {
  const TimeSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Time sheet')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const TimesheetDisplayWidget(),
          const WatchCounter(),
          const SizedBox(height: 100),
          Row(
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
                  context.read<TimeSheetBloc>().add(const TimeSheetOutEvent());
                },
                text: 'Sortir',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              AdaptiveButton(
                onPressed: () {
                  DateTime now = DateTime.now();
                  context
                      .read<TimeSheetBloc>()
                      .add(TimeSheetStartBreakEvent(now));
                },
                text: 'Début pause',
              ),
              AdaptiveButton(
                onPressed: () {
                  context
                      .read<TimeSheetBloc>()
                      .add(const TimeSheetEndBreakEvent());
                },
                text: 'Fin pause',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
