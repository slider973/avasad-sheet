import 'package:intl/intl.dart';

class TimesheetEntry {
  int? id;
  String dayDate;
  String dayOfWeekDate;
  String startMorning;
  String endMorning;
  String startAfternoon;
  String endAfternoon;

  TimesheetEntry(
      {this.id,
      required this.dayDate,
      required this.dayOfWeekDate,
      required this.startMorning,
      required this.endMorning,
      required this.startAfternoon,
      required this.endAfternoon});

  @override
  String toString() {
    return 'TimesheetEntry{id: $id, dayDate: $dayDate, dayOfWeekDate: $dayOfWeekDate, startMorning: $startMorning, endMorning: $endMorning, startAfternoon: $startAfternoon, endAfternoon: $endAfternoon}';
  }

  String get currentState {
    if (startMorning.isEmpty) return 'Non commencé';
    if (endMorning.isEmpty) return 'Entrée';
    if (startAfternoon.isEmpty) return 'Pause';
    if (endAfternoon.isEmpty) return 'Reprise';
    return 'Sortie';
  }

  double get progression {
    if (startMorning.isEmpty) return 0.0;
    if (endMorning.isEmpty) return 0.25;
    if (startAfternoon.isEmpty) return 0.5;
    if (endAfternoon.isEmpty) return 0.75;
    return 1.0;
  }

  DateTime? get lastPointage {
    final format = DateFormat('dd-MMM-yy HH:mm');
    if (endAfternoon.isNotEmpty) return format.parse('$dayDate $endAfternoon');
    if (startAfternoon.isNotEmpty)
      return format.parse('$dayDate $startAfternoon');
    if (endMorning.isNotEmpty) return format.parse('$dayDate $endMorning');
    if (startMorning.isNotEmpty) return format.parse('$dayDate $startMorning');
    return null;
  }
}
