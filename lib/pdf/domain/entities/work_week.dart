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

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours:$minutes";
  }
}
