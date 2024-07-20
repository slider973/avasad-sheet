import '../../../domain/entities/timesheet_entry.dart';

class Event {
  final TimesheetEntry entry;
  final bool isAbsence;

  const Event(this.entry, {this.isAbsence = false});
  @override
  String toString() {
    return 'Matin: ${entry.startMorning} - ${entry.endMorning}\n'
        'Après-midi: ${entry.startAfternoon} - ${entry.endAfternoon}';
  }
}