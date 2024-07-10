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
      appBar: AppBar(title: const Text('Pointage')),
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

