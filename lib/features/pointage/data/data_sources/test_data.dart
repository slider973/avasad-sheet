import '../../domain/entities/timesheet_entry.dart';
import '../utils/time_sheet_utils.dart';

// final List<TimesheetEntry> testData = [
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-20'), 'Mercredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-21'), 'Jeudi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-22'), 'Vendredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-23'), 'Samedi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-24'), 'Dimanche', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-25'), 'Lundi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-26'), 'Mardi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-27'), 'Mercredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-28'), 'Jeudi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-29'), 'Vendredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-30'), 'Samedi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2023-12-31'), 'Dimanche', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-01'), 'Lundi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-02'), 'Mardi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-03'), 'Mercredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-04'), 'Jeudi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-05'), 'Vendredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-06'), 'Samedi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-07'), 'Dimanche', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-08'), 'Lundi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-09'), 'Mardi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-10'), 'Mercredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-11'), 'Jeudi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-12'), 'Vendredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-13'), 'Samedi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-14'), 'Dimanche', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-15'), 'Lundi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-16'), 'Mardi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-17'), 'Mercredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-18'), 'Jeudi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-19'), 'Vendredi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-20'), 'Samedi', '08:00', '12:00', '13:00', '17:00'),
//   TimesheetEntry(TimeSheetUtils.convertFormatDate('2024-01-21'), 'Dimanche', '08:00', '12:00', '13:00', '17:00')
// ];
