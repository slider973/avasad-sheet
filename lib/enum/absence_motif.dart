enum AbsenceMotif {
  publicHoliday("Jour férié"),
  leaveDay("Congés"),
  sickness("Maladie");

  final String value;

  const AbsenceMotif(this.value);
}