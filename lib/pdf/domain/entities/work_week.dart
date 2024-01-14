import 'work_day.dart';

class WorkWeek {
  List<Workday> workday;

  WorkWeek(this.workday);

  Duration calculateTotalWeekHours() {
    Duration total = const Duration();
    for (var day in workday) {
      total += day.calculateTotalHours();
    }
    return total;
  }
}
