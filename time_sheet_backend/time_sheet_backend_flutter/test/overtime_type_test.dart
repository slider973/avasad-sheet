import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/enum/overtime_type.dart';

void main() {
  group('OvertimeType', () {
    group('includesWeekday', () {
      test('should return true for WEEKDAY_ONLY', () {
        expect(OvertimeType.WEEKDAY_ONLY.includesWeekday, isTrue);
      });

      test('should return false for WEEKEND_ONLY', () {
        expect(OvertimeType.WEEKEND_ONLY.includesWeekday, isFalse);
      });

      test('should return true for BOTH', () {
        expect(OvertimeType.BOTH.includesWeekday, isTrue);
      });

      test('should return false for NONE', () {
        expect(OvertimeType.NONE.includesWeekday, isFalse);
      });
    });

    group('includesWeekend', () {
      test('should return false for WEEKDAY_ONLY', () {
        expect(OvertimeType.WEEKDAY_ONLY.includesWeekend, isFalse);
      });

      test('should return true for WEEKEND_ONLY', () {
        expect(OvertimeType.WEEKEND_ONLY.includesWeekend, isTrue);
      });

      test('should return true for BOTH', () {
        expect(OvertimeType.BOTH.includesWeekend, isTrue);
      });

      test('should return false for NONE', () {
        expect(OvertimeType.NONE.includesWeekend, isFalse);
      });
    });

    group('hasNoOvertime', () {
      test('should return true for NONE', () {
        expect(OvertimeType.NONE.hasNoOvertime, isTrue);
      });

      test('should return false for WEEKDAY_ONLY', () {
        expect(OvertimeType.WEEKDAY_ONLY.hasNoOvertime, isFalse);
      });

      test('should return false for WEEKEND_ONLY', () {
        expect(OvertimeType.WEEKEND_ONLY.hasNoOvertime, isFalse);
      });

      test('should return false for BOTH', () {
        expect(OvertimeType.BOTH.hasNoOvertime, isFalse);
      });
    });

    group('description', () {
      test('should return correct description for NONE', () {
        expect(OvertimeType.NONE.description,
            equals('Aucune heure supplémentaire'));
      });

      test('should return correct description for WEEKDAY_ONLY', () {
        expect(OvertimeType.WEEKDAY_ONLY.description,
            equals('Heures supplémentaires en semaine uniquement'));
      });

      test('should return correct description for WEEKEND_ONLY', () {
        expect(OvertimeType.WEEKEND_ONLY.description,
            equals('Heures supplémentaires le weekend uniquement'));
      });

      test('should return correct description for BOTH', () {
        expect(OvertimeType.BOTH.description,
            equals('Heures supplémentaires en semaine et weekend'));
      });
    });

    group('Enum Values', () {
      test('should have all expected enum values', () {
        final values = OvertimeType.values;

        expect(values, contains(OvertimeType.NONE));
        expect(values, contains(OvertimeType.WEEKDAY_ONLY));
        expect(values, contains(OvertimeType.WEEKEND_ONLY));
        expect(values, contains(OvertimeType.BOTH));
        expect(values.length, equals(4));
      });

      test('should maintain consistent enum ordering', () {
        final values = OvertimeType.values;

        expect(values[0], equals(OvertimeType.NONE));
        expect(values[1], equals(OvertimeType.WEEKDAY_ONLY));
        expect(values[2], equals(OvertimeType.WEEKEND_ONLY));
        expect(values[3], equals(OvertimeType.BOTH));
      });
    });

    group('Logical Combinations', () {
      test('should have mutually exclusive weekday and weekend only types', () {
        expect(OvertimeType.WEEKDAY_ONLY.includesWeekday, isTrue);
        expect(OvertimeType.WEEKDAY_ONLY.includesWeekend, isFalse);

        expect(OvertimeType.WEEKEND_ONLY.includesWeekday, isFalse);
        expect(OvertimeType.WEEKEND_ONLY.includesWeekend, isTrue);
      });

      test('should have BOTH type include both weekday and weekend', () {
        expect(OvertimeType.BOTH.includesWeekday, isTrue);
        expect(OvertimeType.BOTH.includesWeekend, isTrue);
        expect(OvertimeType.BOTH.hasNoOvertime, isFalse);
      });

      test('should have NONE type exclude all overtime', () {
        expect(OvertimeType.NONE.includesWeekday, isFalse);
        expect(OvertimeType.NONE.includesWeekend, isFalse);
        expect(OvertimeType.NONE.hasNoOvertime, isTrue);
      });
    });
  });
}
