import 'work_day.dart';

class WorkWeek {
  List<Workday> days;

  WorkWeek(this.days);

  Duration calculateTotalWeekHours() {
    Duration total = const Duration();
    for (var day in days) {
      total += day.calculateTotalHours();
    }
    return total;
  }
}
