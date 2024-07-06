import '../../../domain/entities/timesheet_entry.dart';

class Event {
  final TimesheetEntry entry;
  const Event(this.entry);

  @override
  String toString() {
    return 'Matin: ${entry.startMorning} - ${entry.endMorning}\n'
        'Après-midi: ${entry.startAfternoon} - ${entry.endAfternoon}';
  }
}