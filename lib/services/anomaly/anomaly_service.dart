import 'package:isar/isar.dart';
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

    DateTime currentDay = startOfPeriod;

    while (currentDay.isBefore(endOfPeriod)) {
      if (currentDay.weekday == DateTime.saturday || currentDay.weekday == DateTime.sunday) {
        currentDay = currentDay.add(const Duration(days: 1));
        continue;
      }

      final existingEntry = await isar.timeSheetEntryModels
          .filter()
          .dayDateBetween(currentDay, currentDay.add(const Duration(days: 1)))
          .findFirst();

      if (existingEntry != null) {
        await anomalyGenerator.generateForTimeSheetEntry(currentDay, existingEntry);
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }
  }
}
