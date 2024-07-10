import '../../data/models/timesheet_entry/timesheet_entry.dart';
import '../../data/utils/time_sheet_utils.dart';
import '../entities/timesheet_entry.dart';

class TimesheetEntryMapper {
  static TimesheetEntry fromModel(TimeSheetEntryModel model) {
    return TimesheetEntry(
      id: model.id,
      TimeSheetUtils.formatDate(model.dayDate),
      model.dayOfWeekDate,
      model.startMorning,
      model.endMorning,
      model.startAfternoon,
      model.endAfternoon,
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
    );
    model.id = entity.id!;
    return model;
  }
}