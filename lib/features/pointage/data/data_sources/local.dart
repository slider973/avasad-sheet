import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:time_sheet/features/absence/data/models/absence.dart';
import 'package:time_sheet/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/services/logger_service.dart';

import '../../domain/data_source/time_sheet.dart';
import '../../domain/mapper/timesheetEntry.mapper.dart';
import '../../presentation/widgets/pointage_widget/pointage_absence.dart';
import '../models/anomalies/anomalies.dart';
import '../models/generated_pdf/generated_pdf.dart';

class LocalDatasourceImpl implements LocalDataSource {
  Isar isar;

  LocalDatasourceImpl(this.isar);

  @override
  Future<int> saveTimeSheet(TimeSheetEntryModel entryModel) async {
    print("🚀 Début saveTimeSheet");
    print("📝 EntryModel à sauvegarder:");
    print("  - id: ${entryModel.id}");
    print("  - dayDate: ${entryModel.dayDate}");

    // Lire l'absence avant la transaction
    final absence = entryModel.absence.value;
    print("  - absence: ${absence != null ? 'présente' : 'absente'}");

    try {
      int id = await isar.writeTxn(() async {
        try {
          print("📦 Début transaction Isar");

          // Gérer l'absence si elle existe
          if (absence != null) {
            print("🏥 Absence détectée");
            final absenceId = await isar.absences.put(absence);
            print("✅ Absence sauvegardée avec id: $absenceId");
          }

          // Sauvegarder l'entrée timesheet
          print("📋 Sauvegarde de l'entrée timesheet");
          final entryId = await isar.timeSheetEntryModels.put(entryModel);
          print("✅ EntryModel sauvegardée avec id: $entryId");

          // Sauvegarder la relation si une absence existe
          if (absence != null) {
            await entryModel.absence.save();
            print("✅ Relation absence sauvegardée");
          }

          print("🏁 Fin transaction avec id: $entryId");
          return entryId;
        } catch (e, stackTrace) {
          print("❌ Erreur dans la transaction: $e");
          print("Stack trace: $stackTrace");
          rethrow;
        }
      });
      print("🎉 Fin saveTimeSheet avec id retourné: $id");
      return id;
    } catch (e, stackTrace) {
      print("❌ Erreur globale dans saveTimeSheet: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  @override
  Future<List<TimeSheetEntryModel>> getTimesheetEntries() async {
    return isar.timeSheetEntryModels.where().findAll();
  }

  @override
  Future<List<TimeSheetEntryModel>> getTimesheetEntriesForWeek(int weekNumber) {
    return isar.timeSheetEntryModels.where().findAll();
  }

  @override
  Future<List<TimeSheetEntryModel>> findEntriesFromMonthOf(
      int monthNumber, int year) {
    logger.i('[LocalDatasourceImpl] findEntriesFromMonthOf $monthNumber $year');

    // Calcul du 21 du mois précédent
    final datePreviousMonth = DateTime(
      year,
      monthNumber - 1,
      21,
    );

    // Si le mois précédent est décembre de l'année précédente
    final adjustedDatePreviousMonth = (monthNumber == 1)
        ? DateTime(year - 1, 12, 21)
        : datePreviousMonth;

    // Calcul du 21 du mois courant
    final dateCurrentMonth = DateTime(year, monthNumber, 21);

    logger.i('[LocalDatasourceImpl] datePreviousMonth $adjustedDatePreviousMonth');
    logger.i('[LocalDatasourceImpl] dateCurrentMonth $dateCurrentMonth');

    return isar.timeSheetEntryModels
        .filter()
        .dayDateBetween(adjustedDatePreviousMonth, dateCurrentMonth)
        .findAll();
  }

  @override
  Future<void> saveGeneratedPdf(GeneratedPdfModel pdf) async {
    await isar.writeTxn(() async {
      await isar.generatedPdfModels.put(pdf);
    });
  }

  @override
  Future<List<GeneratedPdfModel>> getGeneratedPdfs() async {
    return await isar.generatedPdfModels.where().findAll();
  }

  @override
  Future<void> deleteGeneratedPdf(int pdfId) {
    return isar.writeTxn(() async {
      await isar.generatedPdfModels.delete(pdfId);
    });
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntryForDate(String date) {
    return isar.timeSheetEntryModels
        .filter()
        .dayDateEqualTo(DateTime.parse(date))
        .findFirst()
        .then((value) =>
            value == null ? null : TimesheetEntryMapper.fromModel(value));
  }

  @override
  Future<void> deleteTimeSheet(int id) async {
    return isar.writeTxn(() async {
      final timesheet = await isar.timeSheetEntryModels.get(id);
      if (timesheet != null) {
        final absences = await isar.absences
            .filter()
            .timesheetEntry((q) => q.idEqualTo(timesheet.id))
            .findAll();

        for (final absence in absences) {
          await isar.absences.delete(absence.id);
        }

        await isar.timeSheetEntryModels.delete(id);
      }
    });
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntry(String formattedDate) {
    print(6);
    return isar.timeSheetEntryModels
        .filter()
        .dayDateEqualTo(DateTime.parse(formattedDate))
        .findFirst()
        .then((value) =>
            value == null ? null : TimesheetEntryMapper.fromModel(value));
  }

  @override
  Future<TimesheetEntry?> getTimesheetEntryWhitFrenchFormat(
      String formattedDate) async {
    final DateFormat formatter = DateFormat("dd-MMM-yyyy", "fr_FR");
    final model = await isar.timeSheetEntryModels
        .filter()
        .dayDateEqualTo(formatter.parse(formattedDate))
        .findFirst();
    return model != null ? TimesheetEntryMapper.fromModel(model) : null;
  }

  @override
  Future<int> getVacationDaysCount() async {
    final DateTime now = DateTime.now();
    final DateTime startOfYear = DateTime(now.year, 1, 1);
    int usedVacationDays = 0;
    final entries = await isar.timeSheetEntryModels
        .filter()
        .dayDateBetween(startOfYear, now)
        .findAll();

    for (var entry in entries) {
      if (entry.absence.value != null &&
          entry.absence.value!.type == AbsenceType.vacation) {
        usedVacationDays++;
      }
    }

    return usedVacationDays;
  }

  Future<void> createAnomaliesForCurrentMonth() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    // Vérifiez si des anomalies existent déjà pour ce mois
    final existingAnomalies = await isar.anomalyModels
        .filter()
        .detectedDateGreaterThan(firstDayOfMonth.subtract(Duration(days: 1)))
        .findAll();

    if (existingAnomalies.isNotEmpty) {
      print('Les anomalies pour le mois courant existent déjà.');
      return;
    }

    // Créez les anomalies
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    DateTime currentDay = firstDayOfMonth;

    while (currentDay.isBefore(lastDayOfMonth) ||
        currentDay.isAtSameMomentAs(lastDayOfMonth)) {
      final anomaly = AnomalyModel()
        ..detectedDate = currentDay
        ..description =
            "Anomalie détectée pour le ${currentDay.day}/${currentDay.month}/${currentDay.year}"
        ..isResolved = false
        ..type = AnomalyType.missingEntry;

      await isar.writeTxn(() async {
        await isar.anomalyModels.put(anomaly);
      });

      currentDay = currentDay.add(Duration(days: 1));
    }

    print('Anomalies créées pour le mois courant.');
  }
  @override
  Future<int> getLastYearVacationDaysCount() async {
    final DateTime lastYear = DateTime(DateTime.now().year - 1);
    final DateTime startOfLastYear = DateTime(lastYear.year, 1, 1);
    final DateTime endOfLastYear = DateTime(lastYear.year, 12, 31);

    int usedVacationDays = 0;
    final entries = await isar.timeSheetEntryModels
        .filter()
        .dayDateBetween(startOfLastYear, endOfLastYear)
        .findAll();

    for (var entry in entries) {
      if (entry.absence.value != null &&
          entry.absence.value!.type == AbsenceType.vacation) {
        usedVacationDays++;
      }
    }

    return 25 - usedVacationDays; // Jours restants de l'année précédente
  }
}
