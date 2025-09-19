import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_sheet/enum/reminder_type.dart';
import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/features/preference/data/models/reminder_notification.dart';

void main() {
  group('ReminderType', () {
    test('should have correct display names', () {
      expect(ReminderType.clockIn.displayName, 'Clock In');
      expect(ReminderType.clockOut.displayName, 'Clock Out');
    });

    test('should have correct action verbs', () {
      expect(ReminderType.clockIn.actionVerb, 'clock in');
      expect(ReminderType.clockOut.actionVerb, 'clock out');
    });

    test('should serialize and deserialize correctly', () {
      expect(ReminderType.clockIn.toJson(), 'clockIn');
      expect(ReminderType.fromJson('clockIn'), ReminderType.clockIn);
      expect(ReminderType.fromJson('clockOut'), ReminderType.clockOut);
    });

    test('should create from string correctly', () {
      expect(ReminderType.fromString('clockin'), ReminderType.clockIn);
      expect(ReminderType.fromString('clock_in'), ReminderType.clockIn);
      expect(ReminderType.fromString('clockout'), ReminderType.clockOut);
      expect(ReminderType.fromString('clock_out'), ReminderType.clockOut);
    });

    test('should throw error for invalid string', () {
      expect(() => ReminderType.fromString('invalid'), throwsArgumentError);
    });
  });

  group('ReminderSettings', () {
    test('should have correct default settings (disabled by default)', () {
      final defaults = ReminderSettings.defaultSettings;

      // Requirement 1.1: disabled by default
      expect(defaults.enabled, false);
      expect(defaults.clockInTime, const TimeOfDay(hour: 8, minute: 0));
      expect(defaults.clockOutTime, const TimeOfDay(hour: 17, minute: 0));
      expect(defaults.activeDays, {1, 2, 3, 4, 5}); // Monday to Friday
      expect(defaults.respectHolidays, true);
      expect(defaults.snoozeMinutes, 15);
      expect(defaults.maxSnoozes, 2);
    });

    test('should validate clock-out time after clock-in time (requirement 2.4)',
        () {
      final validSettings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 0),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(validSettings.validate(), isNull);

      final invalidSettings = validSettings.copyWith(
        clockOutTime: const TimeOfDay(hour: 7, minute: 0), // Before clock-in
      );

      expect(invalidSettings.validate(),
          contains('Clock-out time must be after clock-in time'));
    });

    test('should validate active days', () {
      final invalidSettings = ReminderSettings.defaultSettings.copyWith(
        activeDays: <int>{}, // Empty set
      );

      expect(invalidSettings.validate(),
          contains('At least one active day must be selected'));

      final invalidDaySettings = ReminderSettings.defaultSettings.copyWith(
        activeDays: {0, 8}, // Invalid day numbers
      );

      expect(invalidDaySettings.validate(),
          contains('Active days must be between 1'));
    });

    test('should validate snooze settings', () {
      final invalidSnoozeMinutes = ReminderSettings.defaultSettings.copyWith(
        snoozeMinutes: 0, // Invalid
      );

      expect(invalidSnoozeMinutes.validate(),
          contains('Snooze minutes must be between 1 and 60'));

      final invalidMaxSnoozes = ReminderSettings.defaultSettings.copyWith(
        maxSnoozes: -1, // Invalid
      );

      expect(invalidMaxSnoozes.validate(),
          contains('Maximum snoozes must be between 0 and 5'));
    });

    test('should check if active on specific day', () {
      final settings = ReminderSettings.defaultSettings.copyWith(
        enabled: true,
        activeDays: {1, 3, 5}, // Monday, Wednesday, Friday
      );

      expect(settings.isActiveOnDay(1), true); // Monday
      expect(settings.isActiveOnDay(2), false); // Tuesday
      expect(settings.isActiveOnDay(3), true); // Wednesday

      // Should return false if disabled
      final disabledSettings = settings.copyWith(enabled: false);
      expect(disabledSettings.isActiveOnDay(1), false);
    });

    test('should calculate work duration correctly', () {
      final settings = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 9, minute: 0),
        clockOutTime: const TimeOfDay(hour: 17, minute: 30),
        activeDays: {1, 2, 3, 4, 5},
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

      expect(settings.workDuration, const Duration(hours: 8, minutes: 30));
    });

    test('should serialize and deserialize correctly', () {
      final original = ReminderSettings(
        enabled: true,
        clockInTime: const TimeOfDay(hour: 8, minute: 30),
        clockOutTime: const TimeOfDay(hour: 17, minute: 15),
        activeDays: {1, 3, 5},
        respectHolidays: false,
        snoozeMinutes: 10,
        maxSnoozes: 3,
      );

      final json = original.toJson();
      final restored = ReminderSettings.fromJson(json);

      expect(restored, equals(original));
    });

    test('should handle invalid JSON gracefully', () {
      expect(
          () => ReminderSettings.fromJson({}), throwsA(isA<FormatException>()));
      expect(() => ReminderSettings.fromJson({'invalid': 'data'}),
          throwsA(isA<FormatException>()));
    });
  });

  group('ReminderNotification', () {
    test('should create clock-in notification correctly', () {
      final scheduledTime = DateTime(2024, 1, 15, 8, 0);
      final notification = ReminderNotification.clockIn(
        id: 1,
        scheduledTime: scheduledTime,
      );

      expect(notification.type, ReminderType.clockIn);
      expect(notification.title, 'Time to Clock In');
      expect(notification.body, contains('Good morning'));
      expect(notification.payload, 'clock_in_reminder');
      expect(notification.snoozeCount, 0);
    });

    test('should create clock-out notification correctly', () {
      final scheduledTime = DateTime(2024, 1, 15, 17, 0);
      final notification = ReminderNotification.clockOut(
        id: 2,
        scheduledTime: scheduledTime,
      );

      expect(notification.type, ReminderType.clockOut);
      expect(notification.title, 'Time to Clock Out');
      expect(notification.body, contains('End of workday'));
      expect(notification.payload, 'clock_out_reminder');
      expect(notification.snoozeCount, 0);
    });

    test('should handle snoozing correctly', () {
      final original = ReminderNotification.clockIn(
        id: 1,
        scheduledTime: DateTime(2024, 1, 15, 8, 0),
      );

      final snoozed = original.snooze(const Duration(minutes: 15));

      expect(snoozed.snoozeCount, 1);
      expect(snoozed.body, contains('Snoozed 1x'));
      expect(snoozed.scheduledTime.isAfter(DateTime.now()), true);
    });

    test('should check snooze eligibility correctly', () {
      final notification = ReminderNotification.clockIn(
        id: 1,
        scheduledTime: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(notification.canSnooze(2), true);

      final maxSnoozed = notification.copyWith(snoozeCount: 2);
      expect(maxSnoozed.canSnooze(2), false);

      final delivered = notification.copyWith(isDelivered: true);
      expect(delivered.canSnooze(2), false);

      final cancelled = notification.copyWith(isCancelled: true);
      expect(cancelled.canSnooze(2), false);
    });

    test('should check pending and overdue status correctly', () {
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      final pastTime = DateTime.now().subtract(const Duration(hours: 1));

      final pendingNotification = ReminderNotification.clockIn(
        id: 1,
        scheduledTime: futureTime,
      );
      expect(pendingNotification.isPending, true);
      expect(pendingNotification.isOverdue, false);

      final overdueNotification = ReminderNotification.clockIn(
        id: 2,
        scheduledTime: pastTime,
      );
      expect(overdueNotification.isPending, false);
      expect(overdueNotification.isOverdue, true);
    });

    test('should generate unique keys correctly', () {
      final date = DateTime(2024, 1, 15, 8, 0);
      final clockInNotification =
          ReminderNotification.clockIn(id: 1, scheduledTime: date);
      final clockOutNotification =
          ReminderNotification.clockOut(id: 2, scheduledTime: date);

      expect(clockInNotification.uniqueKey, 'clockIn_2024-1-15');
      expect(clockOutNotification.uniqueKey, 'clockOut_2024-1-15');
      expect(clockInNotification.uniqueKey,
          isNot(equals(clockOutNotification.uniqueKey)));
    });

    test('should validate notification data', () {
      final validNotification = ReminderNotification.clockIn(
        id: 1,
        scheduledTime: DateTime.now(),
      );
      expect(validNotification.validate(), isNull);

      final invalidId = validNotification.copyWith(id: -1);
      expect(invalidId.validate(),
          contains('Notification ID must be non-negative'));

      final emptyTitle = validNotification.copyWith(title: '');
      expect(emptyTitle.validate(),
          contains('Notification title cannot be empty'));

      final emptyBody = validNotification.copyWith(body: '');
      expect(
          emptyBody.validate(), contains('Notification body cannot be empty'));

      final invalidSnoozeCount = validNotification.copyWith(snoozeCount: -1);
      expect(invalidSnoozeCount.validate(),
          contains('Snooze count cannot be negative'));
    });

    test('should serialize and deserialize correctly', () {
      final original = ReminderNotification.clockIn(
        id: 1,
        scheduledTime: DateTime(2024, 1, 15, 8, 0),
        snoozeCount: 1,
      ).copyWith(isDelivered: true);

      final json = original.toJson();
      final restored = ReminderNotification.fromJson(json);

      expect(restored, equals(original));
    });

    test('should handle invalid JSON gracefully', () {
      expect(() => ReminderNotification.fromJson({}),
          throwsA(isA<FormatException>()));
      expect(() => ReminderNotification.fromJson({'invalid': 'data'}),
          throwsA(isA<FormatException>()));
    });
  });
}
