import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/expense/data/models/expense_category_db_mapper.dart';
import 'package:time_sheet/features/expense/domain/entities/expense_category.dart';

void main() {
  group('ExpenseCategoryDb', () {
    group('dbValue', () {
      test('should produce values accepted by the CHECK constraint', () {
        expect(ExpenseCategory.mileage.dbValue, 'mileage');
        expect(ExpenseCategory.meal.dbValue, 'meals');
        expect(ExpenseCategory.accommodation.dbValue, 'accommodation');
        expect(ExpenseCategory.transport.dbValue, 'transport');
        expect(ExpenseCategory.parking.dbValue, 'parking');
        expect(ExpenseCategory.other.dbValue, 'other');
      });
    });

    group('fromDb', () {
      test('should round-trip every enum value (write then read)', () {
        for (final category in ExpenseCategory.values) {
          expect(ExpenseCategoryDb.fromDb(category.dbValue), category);
        }
      });

      test("should accept legacy 'meal' value (local rows)", () {
        expect(ExpenseCategoryDb.fromDb('meal'), ExpenseCategory.meal);
      });

      test('should fall back to other for unknown or null values', () {
        expect(ExpenseCategoryDb.fromDb(null), ExpenseCategory.other);
        expect(ExpenseCategoryDb.fromDb(''), ExpenseCategory.other);
        // Server-only value without a Dart equivalent.
        expect(ExpenseCategoryDb.fromDb('supplies'), ExpenseCategory.other);
      });
    });
  });
}
