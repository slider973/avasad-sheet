import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

List<TimesheetEntry> generateMockTimeSheetEntries({
  required int monthNumber,
  required int year,
  bool includeWeekends = false
}) {
  // Calculer les dates de début et de fin de la période
  final startDate = DateTime(year, monthNumber, 21);
  final endDate = DateTime(year, monthNumber + 1, 20);

  final entries = <TimesheetEntry>[];
  var currentDate = startDate;
  var id = 1;

  while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
    // Sauter les weekends si includeWeekends est false
    if (!includeWeekends && (currentDate.weekday == DateTime.saturday || currentDate.weekday == DateTime.sunday)) {
      currentDate = currentDate.add(const Duration(days: 1));
      continue;
    }

    final dayNames = {
      1: 'Lundi',
      2: 'Mardi',
      3: 'Mercredi',
      4: 'Jeudi',
      5: 'Vendredi',
      6: 'Samedi',
      7: 'Dimanche',
    };

    final monthNames = {
      1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'May', 6: 'Jun',
      7: 'Jul', 8: 'Aug', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec'
    };

    // Formater la date comme "dd-MMM-yy"
    final formattedDate = '${currentDate.day.toString().padLeft(2, '0')}-'
        '${monthNames[currentDate.month]}-'
        '${currentDate.year.toString().substring(2)}';

    entries.add(
      TimesheetEntry(
        id: id,
        dayDate: formattedDate,
        dayOfWeekDate: dayNames[currentDate.weekday]!,
        startMorning: '09:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '18:00',
        absenceReason: null,
        period: null,
      ),
    );

    id++;
    currentDate = currentDate.add(const Duration(days: 1));
  }

  return entries;
}