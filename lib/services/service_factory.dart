import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../home/presentation/manager/init_data_bloc.dart';
import '../pdf/domain/use_cases/find_pointed_list_usecase.dart';
import '../pdf/domain/use_cases/save_timesheet_entry_usecase.dart';
import '../pdf/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../pdf/presentation/pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';

class ServiceFactory extends StatelessWidget {
  final getIt = GetIt.instance;
  final Widget child;

  ServiceFactory({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider<InitDataBloc>(
        create: (context) => InitDataBloc(),
      ),
      BlocProvider<TimeSheetBloc>(
        create: (context) => TimeSheetBloc(
            saveTimesheetEntryUseCase: getIt<SaveTimesheetEntryUseCase>(),
        )
      ),
      BlocProvider<TimeSheetListBloc>(
        create: (context) => TimeSheetListBloc(
            findPointedListUseCase: getIt<FindPointedListUseCase>(),
        ),
      ),
    ], child: child);
  }
}
