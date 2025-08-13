import 'dart:math';
import 'package:intl/intl.dart';
import '../../../../enum/absence_period.dart';
import '../entities/timesheet_entry.dart';
import '../repositories/timesheet_repository.dart';
import '../entities/timesheet_generation_config.dart';


class GenerateMonthlyTimesheetUseCase {
  final TimesheetRepository repository;
  final Random random = Random();

  GenerateMonthlyTimesheetUseCase(this.repository);

  Future<void> execute([TimesheetGenerationConfig? config, DateTime? targetMonth]) async {
    // Utiliser le mois fourni ou le mois actuel par défaut
    DateTime baseDate = targetMonth ?? DateTime.now();
    
    // Calcul des bornes dynamiques de la période pour le mois sélectionné
    // Gérer le cas de janvier où month - 1 = 0
    DateTime startDate;
    if (baseDate.month == 1) {
      startDate = DateTime(baseDate.year - 1, 12, 21);
    } else {
      startDate = DateTime(baseDate.year, baseDate.month - 1, 21);
    }
    DateTime endDate = DateTime(baseDate.year, baseDate.month, 20);

    print("Start Date: $startDate");
    print("End Date: $endDate");

    // Récupérer TOUTES les entrées existantes pour vérifier celles dans notre période
    List<TimesheetEntry> allEntries = await repository.getTimesheetEntries();
    
    // Filtrer les entrées qui sont dans notre période
    Set<String> existingDates = {};
    Map<String, TimesheetEntry> existingEntriesMap = {};
    
    for (var entry in allEntries) {
      // Parser la date de l'entrée
      DateTime entryDate = DateFormat('dd-MMM-yy').parse(entry.dayDate);
      
      // Vérifier si cette date est dans notre période
      if (!entryDate.isBefore(startDate) && !entryDate.isAfter(endDate)) {
        existingDates.add(entry.dayDate);
        existingEntriesMap[entry.dayDate] = entry;
        print("Found existing entry for: ${entry.dayDate}");
      }
    }

    try {
      // Parcourir les jours de la période
      for (DateTime date = startDate; date.isBefore(endDate.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
        // Ignorer les week-ends
        if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
          String formattedDate = DateFormat('dd-MMM-yy').format(date);
          if (!existingDates.contains(formattedDate)) {
            // Aucune entrée n'existe, on peut générer
            print("Generating entry for: $formattedDate");
            TimesheetEntry entry = _generateDayEntry(date, config);
            await repository.saveTimesheetEntry(entry);
            print("Entry saved for: $formattedDate");
          } else {
            // Une entrée existe, vérifier si elle a des données réelles
            TimesheetEntry existingEntry = existingEntriesMap[formattedDate]!;
            
            // Vérifier si l'entrée a des pointages réels (non vides)
            bool hasRealData = existingEntry.startMorning.isNotEmpty || 
                              existingEntry.endMorning.isNotEmpty ||
                              existingEntry.startAfternoon.isNotEmpty ||
                              existingEntry.endAfternoon.isNotEmpty ||
                              existingEntry.absenceReason != null;
            
            if (hasRealData) {
              print("Entry has real data for $formattedDate, skipping...");
            } else {
              print("Entry exists but is empty for $formattedDate, can be regenerated if needed");
              // Optionnel : supprimer l'entrée vide et regénérer
              // await repository.deleteTimeSheet(existingEntry.id!);
              // TimesheetEntry entry = _generateDayEntry(date, config);
              // await repository.saveTimesheetEntry(entry);
            }
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

    // 1. Générer l'heure de début aléatoire
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

    // 2. Générer l'heure de début de pause
    // S'assurer que la pause commence après le début + un minimum de travail (ex: 3h)
    DateTime earliestLunchStart = startTime.add(Duration(hours: 3));
    DateTime configuredLunchMin = DateTime(
      date.year,
      date.month,
      date.day,
      conf.lunchStartMin.hour,
      conf.lunchStartMin.minute,
    );
    DateTime configuredLunchMax = DateTime(
      date.year,
      date.month,
      date.day,
      conf.lunchStartMax.hour,
      conf.lunchStartMax.minute,
    );
    
    // Utiliser le plus tard entre earliestLunchStart et configuredLunchMin
    DateTime actualLunchMin = earliestLunchStart.isAfter(configuredLunchMin) 
        ? earliestLunchStart 
        : configuredLunchMin;
    
    // S'assurer que actualLunchMin ne dépasse pas configuredLunchMax
    if (actualLunchMin.isAfter(configuredLunchMax)) {
      actualLunchMin = configuredLunchMax;
    }
    
    int lunchStartMinutes = actualLunchMin == configuredLunchMax 
        ? 0 
        : random.nextInt(configuredLunchMax.difference(actualLunchMin).inMinutes + 1);
    DateTime lunchStart = actualLunchMin.add(Duration(minutes: lunchStartMinutes));

    // 3. Générer l'heure de fin de pause
    DateTime configuredLunchEndMin = DateTime(
      date.year,
      date.month,
      date.day,
      conf.lunchEndMin.hour,
      conf.lunchEndMin.minute,
    );
    DateTime configuredLunchEndMax = DateTime(
      date.year,
      date.month,
      date.day,
      conf.lunchEndMax.hour,
      conf.lunchEndMax.minute,
    );
    
    // S'assurer que la fin de pause est après le début de pause (minimum 30 minutes)
    DateTime earliestLunchEnd = lunchStart.add(Duration(minutes: 30));
    DateTime actualLunchEndMin = earliestLunchEnd.isAfter(configuredLunchEndMin) 
        ? earliestLunchEnd 
        : configuredLunchEndMin;
    
    // S'assurer que actualLunchEndMin ne dépasse pas configuredLunchEndMax
    if (actualLunchEndMin.isAfter(configuredLunchEndMax)) {
      actualLunchEndMin = configuredLunchEndMax;
    }
    
    int lunchEndMinutes = actualLunchEndMin == configuredLunchEndMax 
        ? 0 
        : random.nextInt(configuredLunchEndMax.difference(actualLunchEndMin).inMinutes + 1);
    DateTime lunchEnd = actualLunchEndMin.add(Duration(minutes: lunchEndMinutes));

    // 4. Générer l'heure de fin dans la plage [endTimeMin, endTimeMax]
    DateTime configuredEndMin = DateTime(
      date.year,
      date.month,
      date.day,
      conf.endTimeMin.hour,
      conf.endTimeMin.minute,
    );
    DateTime configuredEndMax = DateTime(
      date.year,
      date.month,
      date.day,
      conf.endTimeMax.hour,
      conf.endTimeMax.minute,
    );
    
    // S'assurer que l'heure de fin est au moins 3h après la fin de pause
    DateTime earliestEndTime = lunchEnd.add(Duration(hours: 3));
    DateTime actualEndMin = earliestEndTime.isAfter(configuredEndMin) 
        ? earliestEndTime 
        : configuredEndMin;
    
    // S'assurer que actualEndMin ne dépasse pas configuredEndMax
    if (actualEndMin.isAfter(configuredEndMax)) {
      actualEndMin = configuredEndMax;
    }
    
    int endMinutes = actualEndMin == configuredEndMax 
        ? 0 
        : random.nextInt(configuredEndMax.difference(actualEndMin).inMinutes + 1);
    DateTime endTime = actualEndMin.add(Duration(minutes: endMinutes));
    
    // 5. Vérifier le temps de travail total (optionnel)
    int totalWorkMinutes = lunchStart.difference(startTime).inMinutes + 
                          endTime.difference(lunchEnd).inMinutes;
    int lunchDurationMinutes = lunchEnd.difference(lunchStart).inMinutes;
    print("Generated work time: ${totalWorkMinutes / 60} hours");
    print("Generated lunch duration: ${lunchDurationMinutes} minutes");

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
