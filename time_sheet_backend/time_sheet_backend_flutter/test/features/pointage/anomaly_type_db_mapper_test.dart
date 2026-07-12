import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/data/models/anomalies/anomalies.dart';
import 'package:time_sheet/features/pointage/data/models/anomalies/anomaly_type_db_mapper.dart';

void main() {
  group('AnomalyTypeDb', () {
    group('dbValue', () {
      test('should produce snake_case values accepted by the CHECK', () {
        expect(AnomalyType.insufficientHours.dbValue, 'insufficient_hours');
        expect(AnomalyType.missingEntry.dbValue, 'missing_entry');
        expect(AnomalyType.invalidTimes.dbValue, 'invalid_times');
      });
    });

    group('fromDb', () {
      test('should round-trip every enum value (write then read)', () {
        for (final type in AnomalyType.values) {
          expect(AnomalyTypeDb.fromDb(type.dbValue), type);
        }
      });

      test('should accept legacy camelCase values (local rows)', () {
        expect(
          AnomalyTypeDb.fromDb('insufficientHours'),
          AnomalyType.insufficientHours,
        );
        expect(AnomalyTypeDb.fromDb('missingEntry'), AnomalyType.missingEntry);
        expect(AnomalyTypeDb.fromDb('invalidTimes'), AnomalyType.invalidTimes);
      });

      test('should fall back to missingEntry for unknown or null values', () {
        expect(AnomalyTypeDb.fromDb(null), AnomalyType.missingEntry);
        expect(AnomalyTypeDb.fromDb(''), AnomalyType.missingEntry);
        // Server-only values without a Dart equivalent.
        expect(
          AnomalyTypeDb.fromDb('weekly_compensation'),
          AnomalyType.missingEntry,
        );
      });
    });
  });
}
