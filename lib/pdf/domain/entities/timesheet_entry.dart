class TimesheetEntry {
  String dayDate;
  String dayOfWeekDate;
  String startMorning;
  String endMorning;
  String startAfternoon;
  String endAfternoon;

  TimesheetEntry(this.dayDate, this.dayOfWeekDate, this.startMorning,
      this.endMorning, this.startAfternoon, this.endAfternoon);

  @override
  String toString() {
    return 'TimesheetEntry{dayDate: $dayDate, dayOfWeekDate: $dayOfWeekDate, startMorning: $startMorning, endMorning: $endMorning, startAfternoon: $startAfternoon, endAfternoon: $endAfternoon}';
  }
}
