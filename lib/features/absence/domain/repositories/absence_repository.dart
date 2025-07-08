import '../entities/absence_entity.dart';
import '../value_objects/absence_type.dart';

abstract class AbsenceRepository {
  Future<int> saveAbsence(AbsenceEntity absence);
  Future<List<AbsenceEntity>> getAbsences();
  Future<void> deleteAbsence(int absenceId);
  Future<AbsenceEntity?> getAbsenceById(int id);
  Future<List<AbsenceEntity>> getAbsencesForDateRange(DateTime startDate, DateTime endDate);
  Future<List<AbsenceEntity>> getAbsencesByType(AbsenceType type);
  Future<int> getAbsenceCountForYear(int year, AbsenceType type);
}