part of 'time_sheet_bloc.dart';

abstract class TimeSheetEvent extends Equatable {
  const TimeSheetEvent();
}

class TimeSheetInitialEvent extends TimeSheetEvent {
  const TimeSheetInitialEvent();
  @override
  List<Object> get props => [];
}

class TimeSheetEnterEvent extends TimeSheetEvent {
  final DateTime startTime;

  const TimeSheetEnterEvent(this.startTime);

  @override
  List<Object> get props => [startTime];
}

class TimeSheetOutEvent extends TimeSheetEvent {
  final DateTime endTime;
  const TimeSheetOutEvent(this.endTime);
  @override
  List<Object> get props => [endTime];
}

class TimeSheetStartBreakEvent extends TimeSheetEvent {
  final DateTime startBreakTime;
  const TimeSheetStartBreakEvent(this.startBreakTime);
  @override
  List<Object> get props => [startBreakTime];
}

class TimeSheetEndBreakEvent extends TimeSheetEvent {
  final DateTime endBreakTime;
  const TimeSheetEndBreakEvent(this.endBreakTime);
  @override
  List<Object> get props => [endBreakTime];
}

class GetTimesheetEntriesForWeekEvent extends TimeSheetEvent {
  final int weekNumber;

  const GetTimesheetEntriesForWeekEvent(this.weekNumber);

  @override
  List<Object> get props => [weekNumber];
}


class LoadTimeSheetDataEvent extends TimeSheetEvent {
  final String dateStr;
  const LoadTimeSheetDataEvent(this.dateStr);
  @override
  List<Object> get props => [dateStr];
}

class TimeSheetUpdatePointageEvent extends TimeSheetEvent {
  final String type;
  final DateTime newDateTime;

  const TimeSheetUpdatePointageEvent(this.type, this.newDateTime);

  @override
  List<Object> get props => [type, newDateTime];
}

class UpdateTimeSheetDataEvent extends TimeSheetEvent {
  final TimesheetEntry entry;
  const UpdateTimeSheetDataEvent(this.entry);

  @override
  List<Object?> get props => [entry];
}

class GenerateMonthlyTimesheetEvent extends TimeSheetEvent {
  const GenerateMonthlyTimesheetEvent();

  @override
  List<Object> get props => [];
}
class CheckGenerationStatusEvent extends TimeSheetEvent {
  const CheckGenerationStatusEvent();

  @override
  List<Object> get props => [];
}
class TimeSheetSignalerAbsencePeriodeEvent extends TimeSheetEvent {
  final DateTime dateDebut;
  final DateTime dateFin;
  final String type; // 'Vacances' ou 'Maladie'
  final String raison;

  const TimeSheetSignalerAbsencePeriodeEvent(this.dateDebut, this.dateFin, this.type, this.raison);

  @override
  List<Object> get props => [dateDebut, dateFin, type, raison];
}

class TimeSheetDeleteEntryEvent extends TimeSheetEvent {
  final int entryId;
  const TimeSheetDeleteEntryEvent(this.entryId);

  @override
  List<Object> get props => [entryId];
}