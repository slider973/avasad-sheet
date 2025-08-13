import 'package:isar/isar.dart';
import '../timesheet_entry/timesheet_entry.dart';

part 'anomalies.g.dart';

@collection
class AnomalyModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late DateTime detectedDate;

  late String description;
  late bool isResolved;

  final timesheetEntry = IsarLink<TimeSheetEntryModel>();

  @enumerated
  late AnomalyType type;
}

enum AnomalyType {
  insufficientHours,
  missingEntry,
  invalidTimes
}

extension AnomalyTypeExtension on AnomalyType {
  String get label {
    switch (this) {
      case AnomalyType.insufficientHours:
        return 'Heures insuffisantes';
      case AnomalyType.missingEntry:
        return 'Entrée manquante';
      case AnomalyType.invalidTimes:
        return 'Horaires invalides';
    }
  }

  String get description {
    switch (this) {
      case AnomalyType.insufficientHours:
        return 'Le temps de travail est inférieur à 8h18';
      case AnomalyType.missingEntry:
        return 'Pas de pointage pour cette journée';
      case AnomalyType.invalidTimes:
        return 'Les horaires de pointage sont incohérents';
    }
  }
}