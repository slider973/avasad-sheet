import 'package:isar/isar.dart';
import 'package:time_sheet/features/pointage/data/models/anomalies/anomalies.dart';
import 'package:time_sheet/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';

import 'anomaly_generator.dart';
import 'insufficient_hours_rule.dart';

class AnomalyService {
  final Isar isar;

  AnomalyService(this.isar);

  Future<void> createAnomaliesForCurrentMonth() async {
    final validators = [
      InsufficientHoursRule(),
    ];

    final anomalyGenerator = AnomalyGenerator(isar, validators);

    final now = DateTime.now();
    final startOfPeriod = now.day >= 21
        ? DateTime(now.year, now.month, 21)
        : DateTime(now.year, now.month - 1, 21);
    final endOfPeriod = now.day >= 21
        ? DateTime(now.year, now.month + 1, 20)
        : DateTime(now.year, now.month, 20);

    // Vérifie d'abord si des anomalies existent déjà pour la période
    final existingAnomalies = await isar.anomalyModels
        .filter()
        .detectedDateBetween(
          startOfPeriod.subtract(const Duration(days: 1)),
          endOfPeriod.add(const Duration(days: 1)),
        )
        .findAll();

    if (existingAnomalies.isNotEmpty) {
      // Si des anomalies existent déjà pour cette période, on les met à jour au lieu d'en créer de nouvelles
      await isar.writeTxn(() async {
        for (var anomaly in existingAnomalies) {
          await isar.anomalyModels.delete(anomaly.id);
        }
      });
    }

    DateTime currentDay = startOfPeriod;

    while (currentDay.isBefore(endOfPeriod)) {
      if (currentDay.weekday == DateTime.saturday ||
          currentDay.weekday == DateTime.sunday) {
        currentDay = currentDay.add(const Duration(days: 1));
        continue;
      }

      final existingEntry = await isar.timeSheetEntryModels
          .filter()
          .dayDateBetween(currentDay, currentDay.add(const Duration(days: 1)))
          .findFirst();

      if (existingEntry != null) {
        // Vérifier si une anomalie existe déjà pour cette entrée
        final existingAnomaly = await isar.anomalyModels
            .filter()
            .detectedDateEqualTo(currentDay)
            .findFirst();

        if (existingAnomaly == null) {
          await anomalyGenerator.generateForTimeSheetEntry(
              currentDay, existingEntry);
        }
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }
  }
}
