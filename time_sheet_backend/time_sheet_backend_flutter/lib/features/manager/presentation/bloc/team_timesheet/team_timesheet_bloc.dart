import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/employee_timesheet_entry.dart';
import '../../../domain/use_cases/get_employee_timesheet_usecase.dart';

part 'team_timesheet_event.dart';
part 'team_timesheet_state.dart';

class TeamTimesheetBloc extends Bloc<TeamTimesheetEvent, TeamTimesheetState> {
  final GetEmployeeTimesheetUseCase getEmployeeTimesheetUseCase;

  TeamTimesheetBloc({required this.getEmployeeTimesheetUseCase})
      : super(const TeamTimesheetState()) {
    on<LoadEmployeeTimesheet>(_onLoadTimesheet);
  }

  Future<void> _onLoadTimesheet(
    LoadEmployeeTimesheet event,
    Emitter<TeamTimesheetState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final result = await getEmployeeTimesheetUseCase.execute(
      employeeId: event.employeeId,
      month: event.month,
      year: event.year,
    );

    result.fold(
      // Comportement identique à l'ancienne page : en cas d'échec de
      // chargement, on arrête simplement le loader.
      (failure) => emit(state.copyWith(isLoading: false)),
      (entries) => emit(state.copyWith(entries: entries, isLoading: false)),
    );
  }
}
