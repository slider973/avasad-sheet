import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../../services/logger_service.dart';
import '../../../../../domain/entities/timesheet_entry.dart';
import '../../../../../domain/use_cases/find_pointed_list_usecase.dart';

part 'time_sheet_list_event.dart';

part 'time_sheet_list_state.dart';

class TimeSheetListBloc extends Bloc<TimeSheetListEvent, TimeSheetListState> {
  final FindPointedListUseCase findPointedListUseCase;

  TimeSheetListBloc({required this.findPointedListUseCase}) : super(const TimeSheetListInitial()) {
    on<TimeSheetListEvent>((event, emit) {});
    on<FindTimesheetEntriesEvent>(_findEntries);
  }

  void _findEntries(FindTimesheetEntriesEvent event, Emitter<TimeSheetListState> emit) async {
    try {
      final entries = await findPointedListUseCase.execute();
      emit(TimeSheetListFetchedState(entries));
    } catch (e) {
      logger.e(e.toString());
    }
  }
}
