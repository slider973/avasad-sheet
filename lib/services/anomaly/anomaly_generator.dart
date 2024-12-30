import 'package:isar/isar.dart';
import '../../features/pointage/data/models/anomalies/anomalies.dart';
import '../../features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import 'interface_timeSheetValidator.dart';

class AnomalyGenerator {
  final Isar isar;
  final List<ITimeSheetValidator> validators;

  AnomalyGenerator(this.isar, this.validators);

  Future<void> generateForTimeSheetEntry(DateTime date, TimeSheetEntryModel entry) async {
    for (var validator in validators) {
      // Utiliser chaque règle pour valider et générer des anomalies
      final anomaly = validator.validateAndGenerate(entry, date);

      if (anomaly != null) {
        // Vérifier si l'anomalie existe déjà
        final existingAnomaly = await isar.anomalyModels
            .filter()
            .timesheetEntry((q) => q.idEqualTo(entry.id))
            .typeEqualTo(anomaly.type)
            .descriptionEqualTo(anomaly.description)
            .findFirst();

        if (existingAnomaly == null) {
          // Enregistrer la nouvelle anomalie
          await isar.writeTxn(() async {
            await isar.anomalyModels.put(anomaly);
            await anomaly.timesheetEntry.save();
          });

          print("Anomaly created: ${anomaly.description}");
        } else {
          print("Anomaly already exists for date: $date");
        }
      }
    }
  }
}
