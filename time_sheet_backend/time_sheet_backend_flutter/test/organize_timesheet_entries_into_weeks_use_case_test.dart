import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';


class TestDateFormat {
  DateTime parse(String input) {
    final parts = input.split(' ');
    final dateParts = parts[0].split('-');
    final timeParts = parts[1].split(':');

    return DateTime(
      int.parse(dateParts[2]) + 2000, // Assuming '24' means 2024
      _parseMonth(dateParts[1]),
      int.parse(dateParts[0]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  }

  int _parseMonth(String month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months.indexOf(month) + 1;
  }
}

void main() {
  group('TimesheetEntry', () {
    late TimesheetEntry entry;
    late TestDateFormat testDateFormat;

    setUp(() {
      testDateFormat = TestDateFormat();
      entry = TimesheetEntry(
        id: 1,
        dayDate: '01-Jan-24',
        dayOfWeekDate: 'Lundi',
        startMorning: '09:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '18:00',
        absenceReason: null,
        period: null,
      );
    });

    test('currentState should return correct state', () {
      expect(entry.currentState, 'Sortie');

      entry = entry.copyWith(endAfternoon: '');
      expect(entry.currentState, 'Reprise');

      entry = entry.copyWith(startAfternoon: '');
      expect(entry.currentState, 'Pause');

      entry = entry.copyWith(endMorning: '');
      expect(entry.currentState, 'Entrée');

      entry = entry.copyWith(startMorning: '');
      expect(entry.currentState, 'Non commencé');
    });

    test('progression should return correct value', () {
      expect(entry.progression, 1.0);

      entry = entry.copyWith(endAfternoon: '');
      expect(entry.progression, 0.65);

      entry = entry.copyWith(startAfternoon: '');
      expect(entry.progression, 0.3);

      entry = entry.copyWith(endMorning: '');
      expect(entry.progression, 0.0);

      entry = entry.copyWith(startMorning: '');
      expect(entry.progression, 0.0);
    });

    test('lastPointage should return correct DateTime', () {
      expect(entry.lastPointage, testDateFormat.parse('01-Jan-24 18:00'));

      entry = entry.copyWith(endAfternoon: '');
      expect(entry.lastPointage, testDateFormat.parse('01-Jan-24 13:00'));

      entry = entry.copyWith(startAfternoon: '');
      expect(entry.lastPointage, testDateFormat.parse('01-Jan-24 12:00'));

      entry = entry.copyWith(endMorning: '');
      expect(entry.lastPointage, testDateFormat.parse('01-Jan-24 09:00'));

      entry = entry.copyWith(startMorning: '');
      expect(entry.lastPointage, null);
    });

    test('calculateDailyTotal should return correct duration', () {
      final totalDuration = entry.calculateDailyTotal();
      expect(totalDuration, equals(const Duration(hours: 8)));

      entry = entry.copyWith(endAfternoon: '17:00');
      final reducedDuration = entry.calculateDailyTotal();
      expect(reducedDuration, equals(const Duration(hours: 7)));
    });

    test('calculateMonthlyTotal should return correct total duration', () {
      final entries = [
        entry,
        entry.copyWith(id: 2, dayDate: '02-Jan-24'),
        entry.copyWith(id: 3, dayDate: '03-Jan-24', endAfternoon: '17:00'),
      ];

      final totalDuration = TimesheetEntry.calculateMonthlyTotal(entries);
      expect(totalDuration, equals(const Duration(hours: 23)));
    });

    test('pointagesList should return correct list', () {
      final pointages = entry.pointagesList;
      expect(pointages.length, equals(4));
      expect(pointages[0]['type'], equals('Entrée'));
      expect(pointages[1]['type'], equals('Début pause'));
      expect(pointages[2]['type'], equals('Fin pause'));
      expect(pointages[3]['type'], equals('Fin de journée'));
    });

    test('copyWith should return a new instance with updated values', () {
      final updatedEntry = entry.copyWith(
        id: 2,
        dayDate: '02-Jan-24',
        startMorning: '08:00',
      );

      expect(updatedEntry.id, equals(2));
      expect(updatedEntry.dayDate, equals('02-Jan-24'));
      expect(updatedEntry.startMorning, equals('08:00'));
      expect(updatedEntry.endMorning, equals(entry.endMorning));
      expect(updatedEntry.startAfternoon, equals(entry.startAfternoon));
      expect(updatedEntry.endAfternoon, equals(entry.endAfternoon));
    });
  });
}