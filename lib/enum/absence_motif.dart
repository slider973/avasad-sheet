enum AbsenceMotif {
  publicHoliday("Jour férié"),
  leaveDay("Congé"),
  sickness("Maladie");

  final String value;

  const AbsenceMotif(this.value);
}