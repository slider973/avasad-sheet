import 'dart:math';
import 'package:intl/intl.dart';
import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';

class GenerateMonthlyTimesheetUseCase {
  final TimesheetRepository repository;
  final Random random = Random();

  GenerateMonthlyTimesheetUseCase(this.repository);

  Future<void> execute() async {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month - 1, 21);
    DateTime endDate = DateTime(now.year, now.month, 20);

    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
        TimesheetEntry entry = _generateDayEntry(date);
        await repository.saveTimesheetEntry(entry);
      }
    }
  }

  TimesheetEntry _generateDayEntry(DateTime date) {
    // Génération du temps de travail entre 7h30 (450 min) et 8h18 (498 min)
    int workMinutes = 450 + random.nextInt(49);

    // Heure de début entre 7h00 et 8h30
    DateTime startTime = DateTime(date.year, date.month, date.day, 7, 0);
    startTime = startTime.add(Duration(minutes: random.nextInt(91))); // 0 à 90 minutes après 7h00

    // Pause déjeuner entre 12h00 et 12h30
    DateTime lunchStart = DateTime(date.year, date.month, date.day, 12, 0);
    lunchStart = lunchStart.add(Duration(minutes: random.nextInt(31))); // 0 à 30 minutes après 12h00

    // Durée de la pause entre 60 et 90 minutes
    int lunchDuration = 60 + random.nextInt(31);
    DateTime lunchEnd = lunchStart.add(Duration(minutes: lunchDuration));

    // S'assurer que la fin de pause ne dépasse pas 13h30
    DateTime maxLunchEnd = DateTime(date.year, date.month, date.day, 13, 30);
    if (lunchEnd.isAfter(maxLunchEnd)) {
      lunchEnd = maxLunchEnd;
      lunchDuration = lunchEnd.difference(lunchStart).inMinutes;
    }

    // Calcul de l'heure de fin
    int morningWorkMinutes = lunchStart.difference(startTime).inMinutes;
    int afternoonWorkMinutes = workMinutes - morningWorkMinutes;
    DateTime endTime = lunchEnd.add(Duration(minutes: afternoonWorkMinutes));

    // Vérification que l'heure de fin ne dépasse pas 18:18
    DateTime latestEndTime = DateTime(date.year, date.month, date.day, 18, 18);
    if (endTime.isAfter(latestEndTime)) {
      endTime = latestEndTime;
      // Recalcul du temps de travail de l'après-midi
      afternoonWorkMinutes = endTime.difference(lunchEnd).inMinutes;
      workMinutes = morningWorkMinutes + afternoonWorkMinutes;
    }

    return TimesheetEntry(
      dayDate: DateFormat('dd-MMM-yy').format(date),
      dayOfWeekDate: DateFormat('EEEE').format(date),
      startMorning: DateFormat('HH:mm').format(startTime),
      endMorning: DateFormat('HH:mm').format(lunchStart),
      startAfternoon: DateFormat('HH:mm').format(lunchEnd),
      endAfternoon: DateFormat('HH:mm').format(endTime),
    );
  }
}