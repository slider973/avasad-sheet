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
      period: model.period,
    );
  }

  static TimeSheetEntryModel toModel(TimesheetEntry entity) {
    final model = TimeSheetEntryModel(
      dayDate: TimeSheetUtils.parseDate(entity.dayDate),
      dayOfWeekDate: entity.dayOfWeekDate,
      startMorning: entity.startMorning,
      endMorning: entity.endMorning,
      startAfternoon: entity.startAfternoon,
      endAfternoon: entity.endAfternoon,
      absenceReason: entity.absenceReason ?? '',
      period: entity.period ?? '',
    );
    if (entity.id != null) {
      model.id = entity.id!;
    }
    return model;
  }
}
