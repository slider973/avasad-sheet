import 'package:intl/intl.dart';

class TimesheetEntry {
  int? id;
  String dayDate;
  String dayOfWeekDate;
  String startMorning;
  String endMorning;
  String startAfternoon;
  String endAfternoon;
  final String? absenceReason;

  TimesheetEntry({this.id,
    required this.dayDate,
    required this.dayOfWeekDate,
    required this.startMorning,
    required this.endMorning,
    required this.startAfternoon,
    required this.endAfternoon,
    this.absenceReason
  });

  @override
  String toString() {
    return 'TimesheetEntry{id: $id, dayDate: $dayDate, dayOfWeekDate: $dayOfWeekDate, startMorning: $startMorning, endMorning: $endMorning, startAfternoon: $startAfternoon, endAfternoon: $endAfternoon, absenceReason: $absenceReason}';
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
    if (endMorning.isEmpty) return 0.20;
    if (startAfternoon.isEmpty) return 0.4;
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
  Duration calculateDailyTotal() {
    final format = DateFormat('HH:mm');
    Duration total = Duration.zero;

    if (startMorning.isNotEmpty && endMorning.isNotEmpty) {
      final start = format.parse(startMorning);
      final end = format.parse(endMorning);
      total += end.difference(start);
    }

    if (startAfternoon.isNotEmpty && endAfternoon.isNotEmpty) {
      final start = format.parse(startAfternoon);
      final end = format.parse(endAfternoon);
      total += end.difference(start);
    }

    return total;
  }

  static Duration calculateMonthlyTotal(List<TimesheetEntry> entries) {
    return entries.fold(Duration.zero, (total, entry) => total + entry.calculateDailyTotal());
  }

  List<Map<String, dynamic>> get pointagesList {
    List<Map<String, dynamic>> list = [];
    if (startMorning.isNotEmpty) {
      list.add(
          {'type': 'Entrée', 'heure': _parseDateTime(dayDate, startMorning)});
    }
    if (endMorning.isNotEmpty) {
      list.add({
        'type': 'Début pause',
        'heure': _parseDateTime(dayDate, endMorning)
      });
    }
    if (startAfternoon.isNotEmpty) {
      list.add({
        'type': 'Fin pause',
        'heure': _parseDateTime(dayDate, startAfternoon)
      });
    }
    if (endAfternoon.isNotEmpty) {
      list.add({
        'type': 'Fin de journée',
        'heure': _parseDateTime(dayDate, endAfternoon)
      });
    }
    return list;
  }

  DateTime _parseDateTime(String date, String time) {
    return DateFormat('dd-MMM-yy HH:mm').parse('$date $time');
  }


  // Ajoutez cette méthode
  TimesheetEntry copyWith({
    int? id,
    String? dayDate,
    String? dayOfWeekDate,
    String? startMorning,
    String? endMorning,
    String? startAfternoon,
    String? endAfternoon,
    String? absenceReason,
  }) {
    return TimesheetEntry(
      id: id ?? this.id,
      dayDate: dayDate ?? this.dayDate,
      dayOfWeekDate: dayOfWeekDate ?? this.dayOfWeekDate,
      startMorning: startMorning ?? this.startMorning,
      endMorning: endMorning ?? this.endMorning,
      startAfternoon: startAfternoon ?? this.startAfternoon,
      endAfternoon: endAfternoon ?? this.endAfternoon,
      absenceReason: absenceReason ?? this.absenceReason,

    );
  }
}
