import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/data/models/timesheet_entry/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/mapper/timesheetEntry.mapper.dart';
import 'package:time_sheet/enum/overtime_type.dart';

void main() {
  group('Weekend TimesheetEntry Tests', () {
    test('should create TimesheetEntry with weekend properties', () {
      // Arrange
      final entry = TimesheetEntry(
        dayDate: '14-Dec-24', // Saturday
        dayOfWeekDate: 'Samedi',
        startMorning: '08:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '17:00',
        hasOvertimeHours: false,
        isWeekendDay: true,
        isWeekendOvertimeEnabled: true,
        overtimeType: OvertimeType.WEEKEND_ONLY,
      );

      // Assert
      expect(entry.isWeekendDay, true);
      expect(entry.isWeekendOvertimeEnabled, true);
      expect(entry.overtimeType, OvertimeType.WEEKEND_ONLY);
    });

    test('should calculate weekend hours correctly', () {
      // Arrange
      final entry = TimesheetEntry(
        dayDate: '14-Dec-24', // Saturday
        dayOfWeekDate: 'Samedi',
        startMorning: '08:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '17:00',
        hasOvertimeHours: false,
        isWeekendDay: true,
        isWeekendOvertimeEnabled: true,
        overtimeType: OvertimeType.WEEKEND_ONLY,
      );

      // Act
      final weekendHours = entry.weekendHours;
      final weekendOvertimeHours = entry.weekendOvertimeHours;
      final weekdayOvertimeHours = entry.weekdayOvertimeHours;

      // Assert
      expect(weekendHours, const Duration(hours: 8)); // 4 + 4 hours
      expect(weekendOvertimeHours,
          const Duration(hours: 8)); // All weekend hours are overtime
      expect(weekdayOvertimeHours,
          Duration.zero); // No weekday overtime for weekend entry
    });

    test('should calculate weekday overtime hours correctly', () {
      // Arrange
      final entry = TimesheetEntry(
        dayDate: '16-Dec-24', // Monday
        dayOfWeekDate: 'Lundi',
        startMorning: '08:00',
        endMorning: '12:00',
        startAfternoon: '13:00',
        endAfternoon: '19:00', // 10 hours total
        hasOvertimeHours: true,
        isWeekendDay: false,
        isWeekendOvertimeEnabled: true,
        overtimeType: OvertimeType.WEEKDAY_ONLY,
      );

      // Act
      final weekendHours = entry.weekendHours;
      final weekendOvertimeHours = entry.weekendOvertimeHours;
      final weekdayOvertimeHours = entry.weekdayOvertimeHours;
      final overtimeHours = entry.calculateOvertimeHours();

      // Assert
      expect(weekendHours, Duration.zero); // Not a weekend day
      expect(weekendOvertimeHours, Duration.zero); // Not a weekend day
      expect(weekdayOvertimeHours,
          const Duration(hours: 2)); // 10 - 8 = 2 hours overtime
      expect(
          overtimeHours, const Duration(hours: 2)); // 10 - 8 = 2 hours overtime
    });

    test('should update weekend status in model correctly', () {
      // Arrange
      final model = TimeSheetEntryModel()
        ..dayDate = DateTime(2024, 12, 14) // Saturday
        ..dayOfWeekDate = 'Samedi'
        ..startMorning = '08:00'
        ..endMorning = '12:00'
        ..startAfternoon = '13:00'
        ..endAfternoon = '17:00'
        ..hasOvertimeHours = false
        ..isWeekendOvertimeEnabled = true;

      // Act
      model.updateWeekendStatus();

      // Assert
      expect(model.isWeekendDay, true);
      expect(model.overtimeType, OvertimeType.WEEKEND_ONLY);
    });

    test('should map between entity and model correctly', () {
      // Arrange
      final entity = TimesheetEntry(
        dayDate: '15-Dec-24', // Sunday
        dayOfWeekDate: 'Dimanche',
        startMorning: '09:00',
        endMorning: '13:00',
        startAfternoon: '14:00',
        endAfternoon: '18:00',
        hasOvertimeHours: false,
        isWeekendDay: true,
        isWeekendOvertimeEnabled: true,
        overtimeType: OvertimeType.WEEKEND_ONLY,
      );

      // Act
      final model = TimesheetEntryMapper.toModel(entity);
      final mappedEntity = TimesheetEntryMapper.fromModel(model);

      // Assert
      expect(mappedEntity.isWeekendDay, entity.isWeekendDay);
      expect(mappedEntity.isWeekendOvertimeEnabled,
          entity.isWeekendOvertimeEnabled);
      expect(mappedEntity.overtimeType, entity.overtimeType);
    });
  });
}
