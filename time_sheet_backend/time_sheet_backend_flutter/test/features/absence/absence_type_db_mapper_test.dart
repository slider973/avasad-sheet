import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/absence/data/models/absence_type_db_mapper.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';

void main() {
  group('AbsenceTypeDb', () {
    group('dbValue', () {
      test('should produce values accepted by the CHECK constraint', () {
        expect(AbsenceType.vacation.dbValue, 'vacation');
        expect(AbsenceType.publicHoliday.dbValue, 'holiday');
        expect(AbsenceType.sickLeave.dbValue, 'sick');
        expect(AbsenceType.other.dbValue, 'other');
      });
    });

    group('fromDb', () {
      test('should round-trip every enum value (write then read)', () {
        for (final type in AbsenceType.values) {
          expect(AbsenceTypeDb.fromDb(type.dbValue), type);
        }
      });

      test('should accept legacy camelCase values (local rows)', () {
        expect(AbsenceTypeDb.fromDb('vacation'), AbsenceType.vacation);
        expect(AbsenceTypeDb.fromDb('publicHoliday'), AbsenceType.publicHoliday);
        expect(AbsenceTypeDb.fromDb('sickLeave'), AbsenceType.sickLeave);
        expect(AbsenceTypeDb.fromDb('other'), AbsenceType.other);
      });

      test("should map server-only values 'unpaid' and 'training' to other",
          () {
        expect(AbsenceTypeDb.fromDb('unpaid'), AbsenceType.other);
        expect(AbsenceTypeDb.fromDb('training'), AbsenceType.other);
      });

      test('should fall back to other for unknown or null values', () {
        expect(AbsenceTypeDb.fromDb(null), AbsenceType.other);
        expect(AbsenceTypeDb.fromDb(''), AbsenceType.other);
        expect(AbsenceTypeDb.fromDb('whatever'), AbsenceType.other);
      });
    });
  });
}
