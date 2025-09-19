import '../../../absence/data/models/absence.mapper.dart';
import '../../data/models/timesheet_entry/timesheet_entry.dart';
import '../../data/utils/time_sheet_utils.dart';
import '../entities/timesheet_entry.dart';

class TimesheetEntryMapper {
  static TimesheetEntry fromModel(TimeSheetEntryModel model) {
    return TimesheetEntry(
      id: model.id,
      dayDate: TimeSheetUtils.formatDate(model.dayDate),
      dayOfWeekDate: model.dayOfWeekDate,
      startMorning: model.startMorning,
      endMorning: model.endMorning,
      startAfternoon: model.startAfternoon,
      endAfternoon: model.endAfternoon,
      absenceReason: model.absenceReason,
      absence: model.absence.value?.toEntity(),
      period: model.period,
      hasOvertimeHours: model.hasOvertimeHours,
      isWeekendDay: model.isWeekendDay,
      isWeekendOvertimeEnabled: model.isWeekendOvertimeEnabled,
      overtimeType: model.overtimeType,
    );
  }

  static TimeSheetEntryModel toModel(TimesheetEntry entity) {
    final model = TimeSheetEntryModel()
      ..dayDate = TimeSheetUtils.parseDate(entity.dayDate)
      ..dayOfWeekDate = entity.dayOfWeekDate
      ..startMorning = entity.startMorning
      ..endMorning = entity.endMorning
      ..startAfternoon = entity.startAfternoon
      ..absenceReason = entity.absenceReason ?? ''
      ..period = entity.period ?? ''
      ..endAfternoon = entity.endAfternoon
      ..hasOvertimeHours = entity.hasOvertimeHours
      ..isWeekendDay = entity.isWeekendDay
      ..isWeekendOvertimeEnabled = entity.isWeekendOvertimeEnabled
      ..overtimeType = entity.overtimeType;

    // Update weekend status based on the date
    model.updateWeekendStatus();

    if (entity.absence != null) {
      model.absence.value = AbsenceMapper.fromEntity(entity.absence!);
    }
    if (entity.id != null) {
      model.id = entity.id!;
    }
    return model;
  }
}
