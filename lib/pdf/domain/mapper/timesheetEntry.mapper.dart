import '../../data/models/timesheet_entry.dart';
import '../../data/utils/time_sheet_utils.dart';
import '../entities/timesheet_entry.dart';

class TimesheetEntryMapper {
  static TimesheetEntry fromModel(TimeSheetEntryModel model) {
    return TimesheetEntry(
      TimeSheetUtils.formatDate(model.dayDate),
      model.dayOfWeekDate,
      model.startMorning,
      model.endMorning,
      model.startAfternoon,
      model.endAfternoon,
    );
  }

  static TimeSheetEntryModel toModel(TimesheetEntry entity) {
    final model = TimeSheetEntryModel();
    model.dayDate = TimeSheetUtils.parseDate(entity.dayDate);
    model.dayOfWeekDate = entity.dayOfWeekDate;
    model.startMorning = entity.startMorning;
    model.endMorning = entity.endMorning;
    model.startAfternoon = entity.startAfternoon;
    model.endAfternoon = entity.endAfternoon;
    return model;
  }
}