getFirstDay() {
  DateTime current = DateTime.now();
  if(current.month == DateTime.january) {
    return DateTime(current.year - 1, 12, 21);
  }
  return DateTime(current.year, current.month, 1);
}
