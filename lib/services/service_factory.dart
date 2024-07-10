import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../features/bottom_nav_tab/presentation/pages/bloc/bottom_navigation_bar_bloc.dart';
import '../features/preference/domain/use_cases/get_signature_usecase.dart';
import '../features/preference/domain/use_cases/get_user_preference_use_case.dart';
import '../features/preference/domain/use_cases/set_user_preference_use_case.dart';
import '../features/preference/presentation/manager/preferences_bloc.dart';
import '../features/time_sheet/data/repositories/timesheet_repository_impl.dart';
import '../features/time_sheet/domain/use_cases/find_pointed_list_usecase.dart';
import '../features/time_sheet/domain/use_cases/get_today_timesheet_entry_use_case.dart';
import '../features/time_sheet/domain/use_cases/save_timesheet_entry_usecase.dart';
import '../features/time_sheet/presentation/pages/pdf/bloc/pdf_bloc.dart';
import '../features/time_sheet/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../features/time_sheet/presentation/pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';

class ServiceFactory extends StatelessWidget {
  final getIt = GetIt.instance;
  final Widget child;

  ServiceFactory({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: [
      BlocProvider(
        create: (context) => PreferencesBloc(
          getUserPreferenceUseCase: getIt<GetUserPreferenceUseCase>(),
          setUserPreferenceUseCase: getIt<SetUserPreferenceUseCase>(),
        )..add(LoadPreferences()),
      ),
      BlocProvider<TimeSheetBloc>(
          create: (context) => TimeSheetBloc(
                saveTimesheetEntryUseCase: getIt<SaveTimesheetEntryUseCase>(),
            getTodayTimesheetEntryUseCase: getIt<GetTodayTimesheetEntryUseCase>()
              )),
      BlocProvider<TimeSheetListBloc>(
        create: (context) => TimeSheetListBloc(
          findPointedListUseCase: getIt<FindPointedListUseCase>(),
        ),
      ),
      BlocProvider<BottomNavigationBarBloc>(
        create: (context) => BottomNavigationBarBloc(),
      ),
      BlocProvider<PdfBloc>(
        create: (context) => PdfBloc(
            getIt<TimesheetRepositoryImpl>(), getIt<GetSignatureUseCase>()),
      ),
    ], child: child);
  }
}
