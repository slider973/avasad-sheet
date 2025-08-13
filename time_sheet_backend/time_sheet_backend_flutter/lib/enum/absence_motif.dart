enum AbsenceMotif {
  leaveDay("Congés"),
  sickness("Maladie"),
  other("Autre");

  final String value;

  const AbsenceMotif(this.value);
}