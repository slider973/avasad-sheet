import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../services/logger_service.dart';
import '../../../../domain/entities/timesheet_entry.dart';

part 'time_sheet_event.dart';

part 'time_sheet_state.dart';

class TimeSheetBloc extends Bloc<TimeSheetEvent, TimeSheetState> {
  TimeSheetBloc()
      : super(TimeSheetDataState(TimesheetEntry(
          '',
          '',
          '',
          '',
          '',
          '',
        ))) {
    on<TimeSheetEnterEvent>((event, Emitter<TimeSheetState> emit) {
      print(state);
      if (state is TimeSheetDataState) {
        TimesheetEntry currentEntry = (state as TimeSheetDataState).entry;
        TimesheetEntry updatedEntry = TimesheetEntry(
          currentEntry.dayDate,
          currentEntry.dayOfWeekDate,
          event.startTime.toString(), // Mettez à jour avec la nouvelle heure
          currentEntry.endMorning,
          currentEntry.startAfternoon,
          currentEntry.endAfternoon,
        );

        emit(TimeSheetDataState(updatedEntry));
      } else {
        // Gérer le cas où l'état n'est pas TimeSheetDataState
        // Vous pourriez vouloir initialiser un nouvel TimesheetEntry ici
        print('non implémenté');
      }
    });
    on<TimeSheetInitialEvent>((event, emit) {
      logger.i('s\'initialiser');
    });
    on<TimeSheetOutEvent>((event, emit) {
      logger.i('Out');
    });
    on<TimeSheetStartBreakEvent>((event, emit) {
      logger.i('StartBreak');
    });
    on<TimeSheetEndBreakEvent>((event, emit) {
      logger.i('EndBreak');
    });
  }
}
