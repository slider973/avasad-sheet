import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';

class Workday {
  TimesheetEntry entry;
  bool isEnabled = true;

  Workday(this.entry);

  // Helper function to parse time string to DateTime
  DateTime _parseTime(String time) {
    print('time: $time');
    DateFormat format = DateFormat.Hm(); // Assuming time is in HH:mm format
    return format.parse(time);
  }

  Duration calculateTotalHours() {
    // Parse start and end times to DateTime
    DateTime startMorning = _parseTime(entry.startMorning);
    DateTime endMorning = _parseTime(entry.endMorning);
    DateTime startAfternoon = _parseTime(entry.startAfternoon);
    DateTime endAfternoon = _parseTime(entry.endAfternoon);

    // Calculate durations
    Duration morningDuration = endMorning.difference(startMorning);
    Duration afternoonDuration = endAfternoon.difference(startAfternoon);

    return morningDuration + afternoonDuration;
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours:$minutes";
  }

  Workday disable() {
    isEnabled = false;
    return this;
  }
}
