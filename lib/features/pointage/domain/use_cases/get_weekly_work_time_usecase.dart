import 'package:intl/intl.dart';

import '../repositories/timesheet_repository.dart';


class GetWeeklyWorkTimeUseCase {
  final TimesheetRepository _repository;

  GetWeeklyWorkTimeUseCase(this._repository);

  Future<Duration> execute(String date) async {
    DateTime currentDate = DateFormat("dd-MMM-yy").parse(date);
    DateTime startOfWeek = currentDate.subtract(Duration(days: currentDate.weekday - 1));
    DateTime endOfWeek = startOfWeek.add(Duration(days: 6));

    Duration totalWorkTime = Duration.zero;

    for (int i = 0; i < 7; i++) {
      DateTime day = startOfWeek.add(Duration(days: i));
      String formattedDate = DateFormat("dd-MMM-yy").format(day);
      final entry = await _repository.getTimesheetEntry(formattedDate);

      if (entry != null) {
        totalWorkTime += entry.calculateDailyTotal();
      }
    }

    return totalWorkTime;
  }
}