import 'package:intl/intl.dart';

class DateGenerator {
  DateTime startDate;
  DateTime endDate;
  List<String> dateList = [];

  DateGenerator(int year, int month)
      : startDate = DateTime(year, month - 1, 21),
        endDate = DateTime(year, month, 20);

  // Étape 1: Ajuster la date de début au samedi précédent le plus proche
  DateGenerator adjustStartDate() {
    var oldStartDay = startDate;
    while (startDate.weekday != DateTime.saturday) {
      startDate = startDate.subtract(const Duration(days: 1));
    }
    // // Reculer d'une semaine supplémentaire si nécessaire
    if (oldStartDay.weekday == DateTime.saturday) {
      startDate = startDate.subtract(const Duration(days: 7));
    }
    return this;
  }

  // Étape 2: Générer la liste des dates
  DateGenerator generateDates() {
    for (DateTime date = startDate;
        date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
        date = date.add(const Duration(days: 1))) {
      dateList.add(DateFormat('dd-MMM-yy').format(date));
    }
    return this;
  }

  // Méthode pour obtenir le résultat final
  List<String> getDates() {
    return dateList;
  }
}

List<String> generateDateList(int year, int month) {
  return DateGenerator(year, month)
      .adjustStartDate()
      .generateDates()
      .getDates();
}
