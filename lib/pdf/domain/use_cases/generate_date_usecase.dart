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
    _makePeriod(endDate);
    return this;
  }

  void _makePeriod(DateTime dateParam, [DateTime? startDateParams]) {
    for (DateTime date = startDateParams ?? startDate;
        date.isBefore(dateParam) || date.isAtSameMomentAs(dateParam);
        date = date.add(const Duration(days: 1))) {
      dateList.add(DateFormat('dd-MMM-yy').format(date));
    }
  }

  // Étape 3: Générer la liste des dates
  DateGenerator generateDatesOfEndOfMonth() {
    // Créer une nouvelle date au début du mois suivant
    DateTime beginningNextMonth = (endDate.month < 12)
        ? DateTime(endDate.year, endDate.month + 1, 1)
        : DateTime(endDate.year + 1, 1, 1);

    // Reculer d'un jour pour obtenir la fin du mois en cours
    var endOfMonth = beginningNextMonth.subtract(const Duration(days: 1));
    _makePeriod(endOfMonth, endDate);
    print("La fin du mois est : ${DateFormat('dd-MMM-yy').format(endOfMonth)}");

    return this;
  }

  // Méthode pour obtenir le résultat final
  List<String> getDates() {
    return dateList;
  }
}

List<String> generateDateListUseCase(int year, int month) {
  return DateGenerator(year, month)
      .adjustStartDate()
      .generateDates()
      .generateDatesOfEndOfMonth()
      .getDates();
}
