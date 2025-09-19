import 'package:intl/intl.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/enum/overtime_type.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';

class TimesheetEntry {
  int? id;
  String dayDate;
  String dayOfWeekDate;
  String startMorning;
  String endMorning;
  String startAfternoon;
  String endAfternoon;
  final String? absenceReason;
  final AbsenceEntity? absence;
  final String? period;
  final bool hasOvertimeHours;
  final bool isWeekendDay;
  final bool isWeekendOvertimeEnabled;
  final OvertimeType overtimeType;

  TimesheetEntry({
    this.id,
    required this.dayDate,
    required this.dayOfWeekDate,
    required this.startMorning,
    required this.endMorning,
    required this.startAfternoon,
    required this.endAfternoon,
    this.absence,
    this.absenceReason,
    this.period,
    this.hasOvertimeHours = false,
    this.isWeekendDay = false,
    this.isWeekendOvertimeEnabled = true,
    this.overtimeType = OvertimeType.NONE,
  });

  @override
  String toString() {
    return 'TimesheetEntry{id: $id, dayDate: $dayDate, dayOfWeekDate: $dayOfWeekDate, startMorning: $startMorning, endMorning: $endMorning, startAfternoon: $startAfternoon, endAfternoon: $endAfternoon, absenceReason: $absenceReason, period: $period}';
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
    if (endMorning.isEmpty) return 0.0;
    if (startAfternoon.isEmpty) return 0.3;
    if (endAfternoon.isEmpty) return 0.65;
    return 1.0;
  }

  /// Retourne la date sous forme de DateTime
  DateTime? get date {
    try {
      return DateFormat('dd-MMM-yy').parse(dayDate);
    } catch (e) {
      return null;
    }
  }

  DateTime? get lastPointage {
    final format = DateFormat('dd-MMM-yy HH:mm');
    if (endAfternoon.isNotEmpty) return format.parse('$dayDate $endAfternoon');
    if (startAfternoon.isNotEmpty) {
      return format.parse('$dayDate $startAfternoon');
    }
    if (endMorning.isNotEmpty) return format.parse('$dayDate $endMorning');
    if (startMorning.isNotEmpty) return format.parse('$dayDate $startMorning');
    return null;
  }

  Duration calculateDailyTotal() {
    final format = DateFormat('HH:mm');
    Duration total = Duration.zero;

    if (absence != null) {
      return Duration.zero;
    }

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
    return entries.fold(
        Duration.zero, (total, entry) => total + entry.calculateDailyTotal());
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

  /// Returns true if this entry is for a weekend day
  bool get isWeekend {
    final entryDate = date;
    if (entryDate == null) return false;
    return WeekendDetectionService().isWeekend(entryDate);
  }

  /// Returns the total hours worked on weekend days
  Duration get weekendHours {
    if (!isWeekend) return Duration.zero;
    return calculateDailyTotal();
  }

  /// Returns overtime hours worked on weekdays only
  Duration get weekdayOvertimeHours {
    if (isWeekend || !hasOvertimeHours) return Duration.zero;
    return calculateOvertimeHours();
  }

  /// Returns overtime hours worked on weekend days
  Duration get weekendOvertimeHours {
    if (!isWeekend) return Duration.zero;
    return calculateDailyTotal(); // All weekend hours are considered overtime
  }

  /// Calculates overtime hours for weekday entries
  /// This method calculates overtime based on a standard 8-hour workday
  Duration calculateOvertimeHours() {
    if (absence != null) return Duration.zero;

    final totalHours = calculateDailyTotal();
    const standardWorkDay = Duration(hours: 8);

    if (totalHours > standardWorkDay) {
      return totalHours - standardWorkDay;
    }

    return Duration.zero;
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
    AbsenceEntity? absence,
    String? period,
    bool? hasOvertimeHours,
    bool? isWeekendDay,
    bool? isWeekendOvertimeEnabled,
    OvertimeType? overtimeType,
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
      period: period ?? this.period,
      absence: absence ?? this.absence,
      hasOvertimeHours: hasOvertimeHours ?? this.hasOvertimeHours,
      isWeekendDay: isWeekendDay ?? this.isWeekendDay,
      isWeekendOvertimeEnabled:
          isWeekendOvertimeEnabled ?? this.isWeekendOvertimeEnabled,
      overtimeType: overtimeType ?? this.overtimeType,
    );
  }
}
