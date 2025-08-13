import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/services/injection_container.dart';
import '../../widgets/timesheet_entries_view.dart';
import 'bloc/time_sheet_list/time_sheet_list_bloc.dart';
import '../../../domain/use_cases/find_pointed_list_usecase.dart';

class TimeSheetPage extends StatelessWidget {
  const TimeSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimeSheetListBloc(
        findPointedListUseCase: getIt<FindPointedListUseCase>(),
      )..add(const FindTimesheetEntriesEvent()),
      child: TimesheetEntriesWidget(),
    );
  }
}