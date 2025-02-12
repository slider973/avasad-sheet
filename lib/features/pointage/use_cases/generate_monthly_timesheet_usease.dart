import 'dart:math';
import 'package:intl/intl.dart';
import '../../../../enum/absence_period.dart';
import '../domain/entities/timesheet_entry.dart';
import '../domain/repositories/timesheet_repository.dart';
import '../domain/entities/timesheet_generation_config.dart';


class GenerateMonthlyTimesheetUseCase {
  final TimesheetRepository repository;
  final Random random = Random();

  GenerateMonthlyTimesheetUseCase(this.repository);

  Future<void> execute([TimesheetGenerationConfig? config]) async {
    DateTime now = DateTime.now();

    // Calcul des bornes dynamiques de la période
    DateTime startDate = now.day >= 21
        ? DateTime(now.year, now.month, 21)
        : DateTime(now.year, now.month - 1, 21);
    DateTime endDate = now.day >= 21
        ? DateTime(now.year, now.month + 1, 20)
        : DateTime(now.year, now.month, 20);

    print("Start Date: $startDate");
    print("End Date: $endDate");

    // Récupérer les entrées existantes pour la période
    List<TimesheetEntry> existingEntries = await repository.getTimesheetEntriesForMonth(now.month);
    Set<String> existingDates = existingEntries.map((e) => e.dayDate).toSet();

    try {
      // Parcourir les jours de la période
      for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
        // Ignorer les week-ends
        if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
          String formattedDate = DateFormat('dd-MMM-yy').format(date);
          if (!existingDates.contains(formattedDate)) {
            print("Generating entry for: $formattedDate");
            TimesheetEntry entry = _generateDayEntry(date, config);
            await repository.saveTimesheetEntry(entry);
            print("Entry saved for: $formattedDate");
          } else {
            print("Entry already exists for: $formattedDate");
          }
        }
      }
    } catch (e) {
      print('Error while generating monthly timesheet: $e');
    }
  }


  TimesheetEntry _generateDayEntry(DateTime date, TimesheetGenerationConfig? config) {
    // Utiliser la configuration fournie ou la configuration par défaut
    final conf = config ?? TimesheetGenerationConfig.defaultConfig();

    // Heure de début entre startTimeMin et startTimeMax
    int startMinutes = random.nextInt(
      conf.startTimeMax.difference(conf.startTimeMin).inMinutes + 1
    );
    DateTime startTime = DateTime(
      date.year,
      date.month,
      date.day,
      conf.startTimeMin.hour,
      conf.startTimeMin.minute,
    ).add(Duration(minutes: startMinutes));

    // Pause déjeuner entre lunchStartMin et lunchStartMax
    int lunchStartMinutes = random.nextInt(
      conf.lunchStartMax.difference(conf.lunchStartMin).inMinutes + 1
    );
    DateTime lunchStart = DateTime(
      date.year,
      date.month,
      date.day,
      conf.lunchStartMin.hour,
      conf.lunchStartMin.minute,
    ).add(Duration(minutes: lunchStartMinutes));

    // Durée de la pause entre lunchDurationMin et lunchDurationMax
    int lunchDuration = conf.lunchDurationMin +
        random.nextInt(conf.lunchDurationMax - conf.lunchDurationMin + 1);
    DateTime lunchEnd = lunchStart.add(Duration(minutes: lunchDuration));

    // Calcul de l'heure de fin en respectant le temps de travail cible (environ 8h)
    int targetWorkMinutes = 480; // 8 heures de travail
    int morningWorkMinutes = lunchStart.difference(startTime).inMinutes;
    int afternoonWorkMinutes = targetWorkMinutes - morningWorkMinutes;
    DateTime endTime = lunchEnd.add(Duration(minutes: afternoonWorkMinutes));

    // Vérification que l'heure de fin ne dépasse pas la limite configurée
    DateTime latestEndTime = DateTime(
      date.year,
      date.month,
      date.day,
      conf.endTimeMax.hour,
      conf.endTimeMax.minute,
    );
    if (endTime.isAfter(latestEndTime)) {
      endTime = latestEndTime;
      // Recalcul du temps de travail de l'après-midi
      afternoonWorkMinutes = endTime.difference(lunchEnd).inMinutes;
    }

    return TimesheetEntry(
      dayDate: DateFormat('dd-MMM-yy').format(date),
      dayOfWeekDate: DateFormat('EEEE').format(date),
      startMorning: DateFormat('HH:mm').format(startTime),
      endMorning: DateFormat('HH:mm').format(lunchStart),
      startAfternoon: DateFormat('HH:mm').format(lunchEnd),
      endAfternoon: DateFormat('HH:mm').format(endTime),
      period: AbsencePeriod.fullDay.value,
    );
  }
}
