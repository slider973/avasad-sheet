import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:time_sheet/features/preference/data/models/reminder_settings.dart';
import 'package:time_sheet/features/preference/data/models/reminder_notification.dart';
import 'package:time_sheet/enum/reminder_type.dart';

void main() {
  group('Clock Reminder Notifications Comprehensive Integration Tests', () {
    group('End-to-End Reminder Flow Integration', () {
      testWidgets(
          'should complete full reminder configuration and validation flow',
          (tester) async {
        // Requirement 1.1, 1.2, 1.3, 1.4, 1.5: Complete reminder flow

        // Step 1: Start with default settings (disabled by default)
        final defaultSettings = ReminderSettings.defaultSettings;
        expect(defaultSettings.enabled,
            isFalse); // Requirement 1.1: disabled by default
        expect(
            defaultSettings.clockInTime, const TimeOfDay(hour: 8, minute: 0));
        expect(
            defaultSettings.clockOutTime, const TimeOfDay(hour: 17, minute: 0));
        expect(defaultSettings.activeDays, {1, 2, 3, 4, 5}); // Monday to Friday
        expect(defaultSettings.respectHolidays, isTrue);
        expect(defaultSettings.snoozeMinutes, 15);
        expect(defaultSettings.maxSnoozes, 2);

        // Step 2: Configure reminder settings
        final reminderSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5}, // Monday to Friday
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Step 3: Validate settings
        expect(reminderSettings.validate(), isNull); // Should be valid
        expect(reminderSettings.hasValidTimeConfiguration, isTrue);

        // Step 4: Test serialization/persistence
        final json = reminderSettings.toJson();
        final deserializedSettings = ReminderSettings.fromJson(json);
        expect(deserializedSettings, equals(reminderSettings));

        // Step 5: Create notifications based on settings
        final clockInNotification = ReminderNotification.clockIn(
          id: 1,
          scheduledTime: DateTime(2025, 1, 20, 8, 0),
        );

        final clockOutNotification = ReminderNotification.clockOut(
          id: 2,
          scheduledTime: DateTime(2025, 1, 20, 17, 0),
        );

        // Step 6: Validate notifications
        expect(clockInNotification.validate(), isNull);
        expect(clockOutNotification.validate(), isNull);

        // Step 7: Test notification content (Requirement 5.1, 5.2)
        expect(clockInNotification.title, isNotEmpty);
        expect(clockInNotification.body, contains('8:00'));
        expect(clockInNotification.body, isNot(contains('!!!')));
        expect(clockInNotification.body, isNot(contains('URGENT')));

        expect(clockOutNotification.title, isNotEmpty);
        expect(clockOutNotification.body, contains('5:00'));
        expect(clockOutNotification.body, isNot(contains('!!!')));
        expect(clockOutNotification.body, isNot(contains('URGENT')));
      });

      testWidgets(
          'should handle invalid settings and provide clear validation errors',
          (tester) async {
        // Test invalid configuration (clock-out before clock-in)
        final invalidSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 17, minute: 0), // 5 PM
          clockOutTime: const TimeOfDay(hour: 8, minute: 0), // 8 AM
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        expect(invalidSettings.validate(), isNotNull); // Should be invalid
        expect(invalidSettings.validate(),
            contains('Clock-out time must be after clock-in time'));
        expect(invalidSettings.hasValidTimeConfiguration, isFalse);

        // Test empty active days
        final noActiveDaysSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {}, // Empty set
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        expect(noActiveDaysSettings.validate(),
            contains('At least one active day must be selected'));

        // Test invalid snooze settings
        final invalidSnoozeSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: 0, // Invalid
          maxSnoozes: 10, // Invalid
        );

        final validationError = invalidSnoozeSettings.validate();
        expect(validationError, isNotNull);
        expect(
            validationError,
            anyOf([
              contains('Snooze minutes must be between 1 and 60'),
              contains('Maximum snoozes must be between 0 and 5'),
            ]));
      });
    });

    group('Notification Interaction and Professional Content', () {
      testWidgets('should handle notification tap and navigation flow',
          (tester) async {
        // Requirement 1.5: Notification tap handling

        final clockInNotification = ReminderNotification.clockIn(
          id: 1,
          scheduledTime:
              DateTime.now().add(const Duration(hours: 1)), // Future time
        );

        final clockOutNotification = ReminderNotification.clockOut(
          id: 2,
          scheduledTime:
              DateTime.now().add(const Duration(hours: 2)), // Future time
        );

        // Test notification payloads for app navigation
        expect(clockInNotification.payload, 'clock_in_reminder');
        expect(clockOutNotification.payload, 'clock_out_reminder');

        // Test notification states
        expect(clockInNotification.isPending, isTrue);
        expect(clockInNotification.isDelivered, isFalse);
        expect(clockInNotification.isCancelled, isFalse);

        // Test state transitions
        final deliveredNotification = clockInNotification.markAsDelivered();
        expect(deliveredNotification.isDelivered, isTrue);
        expect(deliveredNotification.isPending, isFalse);

        final cancelledNotification = clockInNotification.markAsCancelled();
        expect(cancelledNotification.isCancelled, isTrue);
        expect(cancelledNotification.isPending, isFalse);
      });

      testWidgets(
          'should create professional notification content with proper formatting',
          (tester) async {
        // Requirement 5.1, 5.2: Professional notification content

        final morningNotification = ReminderNotification.clockIn(
          id: 1,
          scheduledTime: DateTime(2025, 1, 20, 8, 30),
        );

        final eveningNotification = ReminderNotification.clockOut(
          id: 2,
          scheduledTime: DateTime(2025, 1, 20, 17, 15),
        );

        // Test professional tone
        expect(
            morningNotification.title,
            anyOf([
              contains('Good Morning'),
              contains('Clock In'),
              contains('Work Reminder'),
            ]));

        expect(
            eveningNotification.title,
            anyOf([
              contains('End of Workday'),
              contains('Clock Out'),
              contains('Work Reminder'),
            ]));

        // Test time formatting
        expect(morningNotification.body, contains('8:30'));
        expect(eveningNotification.body, contains('5:15'));

        // Test professional language (no urgent/aggressive language)
        expect(morningNotification.body, isNot(contains('!!!')));
        expect(morningNotification.body, isNot(contains('URGENT')));
        expect(morningNotification.body, isNot(contains('NOW')));

        expect(eveningNotification.body, isNot(contains('!!!')));
        expect(eveningNotification.body, isNot(contains('URGENT')));
        expect(eveningNotification.body, isNot(contains('NOW')));

        // Test helpful content
        expect(
            morningNotification.body,
            anyOf([
              contains('workday'),
              contains('time tracking'),
              contains('clock in'),
            ]));

        expect(
            eveningNotification.body,
            anyOf([
              contains('workday'),
              contains('time tracking'),
              contains('clock out'),
            ]));
      });
    });

    group('Snooze Functionality and Limits Integration', () {
      testWidgets(
          'should handle snooze functionality with professional messaging',
          (tester) async {
        // Requirement 5.4, 5.5: Snooze functionality

        final originalNotification = ReminderNotification.clockIn(
          id: 1,
          scheduledTime: DateTime(2025, 1, 20, 8, 0),
        );

        // Test initial state
        expect(originalNotification.canSnooze(2), isTrue);
        expect(originalNotification.snoozeCount, 0);

        // Test first snooze
        final snoozed1 =
            originalNotification.snooze(const Duration(minutes: 15));
        expect(snoozed1.snoozeCount, 1);
        expect(snoozed1.canSnooze(2), isTrue);
        expect(snoozed1.title, contains('Snoozed'));
        expect(snoozed1.body, contains('snoozed 1 time'));
        expect(
            snoozed1.scheduledTime.isAfter(originalNotification.scheduledTime),
            isTrue);

        // Test second snooze
        final snoozed2 = snoozed1.snooze(const Duration(minutes: 15));
        expect(snoozed2.snoozeCount, 2);
        expect(snoozed2.canSnooze(2), isFalse); // Max reached
        expect(snoozed2.title, contains('Snoozed'));
        expect(snoozed2.body, contains('snoozed 2 times'));

        // Test snooze prevention for delivered notifications
        final deliveredNotification = originalNotification.markAsDelivered();
        expect(deliveredNotification.canSnooze(2), isFalse);

        // Test snooze prevention for cancelled notifications
        final cancelledNotification = originalNotification.markAsCancelled();
        expect(cancelledNotification.canSnooze(2), isFalse);
      });

      testWidgets(
          'should handle snooze limits correctly for different max values',
          (tester) async {
        final notification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          title: 'Test Reminder',
          body: 'Test body',
          payload: 'test_payload',
          snoozeCount: 0,
        );

        // Test with max snoozes = 1
        expect(notification.canSnooze(1), isTrue);
        final snoozed1 = notification.snooze(const Duration(minutes: 15));
        expect(snoozed1.canSnooze(1), isFalse); // Max reached

        // Test with max snoozes = 3
        expect(notification.canSnooze(3), isTrue);
        final snoozed2 = notification.snooze(const Duration(minutes: 15));
        expect(snoozed2.canSnooze(3), isTrue); // Still can snooze
        final snoozed3 = snoozed2.snooze(const Duration(minutes: 15));
        expect(snoozed3.canSnooze(3), isTrue); // Still can snooze
        final snoozed4 = snoozed3.snooze(const Duration(minutes: 15));
        expect(snoozed4.canSnooze(3), isFalse); // Max reached
      });
    });

    group('Weekend and Holiday Handling Integration', () {
      testWidgets('should respect weekend and holiday settings correctly',
          (tester) async {
        // Requirement 3.5: Weekend/holiday handling

        final weekdayOnlySettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5}, // Weekdays only
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        // Test weekday activity
        expect(weekdayOnlySettings.isActiveOnDay(1), isTrue); // Monday
        expect(weekdayOnlySettings.isActiveOnDay(2), isTrue); // Tuesday
        expect(weekdayOnlySettings.isActiveOnDay(3), isTrue); // Wednesday
        expect(weekdayOnlySettings.isActiveOnDay(4), isTrue); // Thursday
        expect(weekdayOnlySettings.isActiveOnDay(5), isTrue); // Friday

        // Test weekend inactivity
        expect(weekdayOnlySettings.isActiveOnDay(6), isFalse); // Saturday
        expect(weekdayOnlySettings.isActiveOnDay(7), isFalse); // Sunday

        // Test weekend work settings
        final weekendWorkSettings = weekdayOnlySettings.copyWith(
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days
        );

        expect(weekendWorkSettings.isActiveOnDay(6), isTrue); // Saturday
        expect(weekendWorkSettings.isActiveOnDay(7), isTrue); // Sunday

        // Test holiday respect setting
        final noHolidayRespectSettings = weekdayOnlySettings.copyWith(
          respectHolidays: false,
        );

        expect(noHolidayRespectSettings.respectHolidays, isFalse);
      });

      testWidgets('should handle custom work schedules correctly',
          (tester) async {
        // Test custom work schedule (e.g., Tuesday to Saturday)
        final customScheduleSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 9, minute: 0),
          clockOutTime: const TimeOfDay(hour: 18, minute: 0),
          activeDays: {2, 3, 4, 5, 6}, // Tuesday to Saturday
          respectHolidays: true,
          snoozeMinutes: 30,
          maxSnoozes: 1,
        );

        expect(
            customScheduleSettings.isActiveOnDay(1), isFalse); // Monday - off
        expect(
            customScheduleSettings.isActiveOnDay(2), isTrue); // Tuesday - work
        expect(customScheduleSettings.isActiveOnDay(3),
            isTrue); // Wednesday - work
        expect(
            customScheduleSettings.isActiveOnDay(4), isTrue); // Thursday - work
        expect(
            customScheduleSettings.isActiveOnDay(5), isTrue); // Friday - work
        expect(
            customScheduleSettings.isActiveOnDay(6), isTrue); // Saturday - work
        expect(
            customScheduleSettings.isActiveOnDay(7), isFalse); // Sunday - off

        // Test work duration calculation
        final workDuration = customScheduleSettings.workDuration;
        expect(workDuration.inHours, 9); // 9 hours
        expect(workDuration.inMinutes, 540); // 9*60 = 540 minutes
      });
    });

    group('Notification State Management Integration', () {
      testWidgets('should track notification states and transitions correctly',
          (tester) async {
        final futureNotification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
          title: 'Future Reminder',
          body: 'This is scheduled for the future',
          payload: 'future_reminder',
        );

        final pastNotification = ReminderNotification(
          id: 2,
          type: ReminderType.clockOut,
          scheduledTime: DateTime.now().subtract(const Duration(hours: 1)),
          title: 'Past Reminder',
          body: 'This was scheduled in the past',
          payload: 'past_reminder',
        );

        // Test initial states
        expect(futureNotification.isPending, isTrue);
        expect(futureNotification.isOverdue, isFalse);
        expect(pastNotification.isPending, isFalse);
        expect(pastNotification.isOverdue, isTrue);

        // Test unique key generation
        expect(futureNotification.uniqueKey,
            isNot(equals(pastNotification.uniqueKey)));

        // Test state transitions
        final deliveredFuture = futureNotification.markAsDelivered();
        expect(deliveredFuture.isDelivered, isTrue);
        expect(deliveredFuture.isPending, isFalse);

        final cancelledPast = pastNotification.markAsCancelled();
        expect(cancelledPast.isCancelled, isTrue);
        expect(cancelledPast.isOverdue,
            isFalse); // Cancelled notifications are not overdue
      });

      testWidgets(
          'should generate unique keys for different notification scenarios',
          (tester) async {
        final clockInToday = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime(2025, 1, 20, 8, 0),
          title: 'Clock In Today',
          body: 'Time to start work',
          payload: 'clock_in_today',
        );

        final clockOutToday = ReminderNotification(
          id: 2,
          type: ReminderType.clockOut,
          scheduledTime: DateTime(2025, 1, 20, 17, 0),
          title: 'Clock Out Today',
          body: 'Time to end work',
          payload: 'clock_out_today',
        );

        final clockInTomorrow = ReminderNotification(
          id: 3,
          type: ReminderType.clockIn,
          scheduledTime: DateTime(2025, 1, 21, 8, 0),
          title: 'Clock In Tomorrow',
          body: 'Time to start work',
          payload: 'clock_in_tomorrow',
        );

        // Test unique keys
        expect(clockInToday.uniqueKey, isNot(equals(clockOutToday.uniqueKey)));
        expect(
            clockInToday.uniqueKey, isNot(equals(clockInTomorrow.uniqueKey)));
        expect(
            clockOutToday.uniqueKey, isNot(equals(clockInTomorrow.uniqueKey)));

        // Test key format
        expect(clockInToday.uniqueKey, contains('clockIn_2025-1-20'));
        expect(clockOutToday.uniqueKey, contains('clockOut_2025-1-20'));
        expect(clockInTomorrow.uniqueKey, contains('clockIn_2025-1-21'));
      });
    });

    group('Serialization and Persistence Integration', () {
      testWidgets(
          'should handle complete serialization flow for complex settings',
          (tester) async {
        final complexSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 7, minute: 45),
          clockOutTime: const TimeOfDay(hour: 16, minute: 30),
          activeDays: {1, 3, 5, 7}, // Monday, Wednesday, Friday, Sunday
          respectHolidays: false,
          snoozeMinutes: 45,
          maxSnoozes: 3,
        );

        // Test serialization
        final json = complexSettings.toJson();
        expect(json, isA<Map<String, dynamic>>());
        expect(json['enabled'], isTrue);
        expect(json['clockInTime'], isA<Map<String, dynamic>>());
        expect(json['clockOutTime'], isA<Map<String, dynamic>>());
        expect(json['activeDays'], isA<List>());
        expect(json['respectHolidays'], isFalse);
        expect(json['snoozeMinutes'], 45);
        expect(json['maxSnoozes'], 3);

        // Test deserialization
        final deserializedSettings = ReminderSettings.fromJson(json);
        expect(deserializedSettings, equals(complexSettings));

        // Test all properties match
        expect(deserializedSettings.enabled, complexSettings.enabled);
        expect(deserializedSettings.clockInTime, complexSettings.clockInTime);
        expect(deserializedSettings.clockOutTime, complexSettings.clockOutTime);
        expect(deserializedSettings.activeDays, complexSettings.activeDays);
        expect(deserializedSettings.respectHolidays,
            complexSettings.respectHolidays);
        expect(
            deserializedSettings.snoozeMinutes, complexSettings.snoozeMinutes);
        expect(deserializedSettings.maxSnoozes, complexSettings.maxSnoozes);
      });

      testWidgets('should handle notification serialization with all states',
          (tester) async {
        final complexNotification = ReminderNotification(
          id: 999,
          type: ReminderType.clockOut,
          scheduledTime: DateTime(2025, 6, 15, 18, 45, 30),
          title: 'Complex Notification',
          body:
              'This is a complex notification with special characters: éàü!@#\$%',
          payload: '{"type":"clockOut","data":{"special":"chars éàü"}}',
          snoozeCount: 2,
          isDelivered: true,
          isCancelled: false,
        );

        // Test serialization
        final json = complexNotification.toJson();
        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], 999);
        expect(json['type'], 'clockOut');
        expect(json['scheduledTime'], '2025-06-15T18:45:30.000');
        expect(json['title'], 'Complex Notification');
        expect(json['body'], contains('special characters'));
        expect(json['payload'], contains('special'));
        expect(json['snoozeCount'], 2);
        expect(json['isDelivered'], isTrue);
        expect(json['isCancelled'], isFalse);

        // Test deserialization
        final deserializedNotification = ReminderNotification.fromJson(json);
        expect(deserializedNotification, equals(complexNotification));

        // Test all properties match
        expect(deserializedNotification.id, complexNotification.id);
        expect(deserializedNotification.type, complexNotification.type);
        expect(deserializedNotification.scheduledTime,
            complexNotification.scheduledTime);
        expect(deserializedNotification.title, complexNotification.title);
        expect(deserializedNotification.body, complexNotification.body);
        expect(deserializedNotification.payload, complexNotification.payload);
        expect(deserializedNotification.snoozeCount,
            complexNotification.snoozeCount);
        expect(deserializedNotification.isDelivered,
            complexNotification.isDelivered);
        expect(deserializedNotification.isCancelled,
            complexNotification.isCancelled);
      });

      testWidgets('should handle serialization errors gracefully',
          (tester) async {
        // Test invalid settings JSON
        expect(() => ReminderSettings.fromJson({}),
            throwsA(isA<FormatException>()));
        expect(() => ReminderSettings.fromJson({'invalid': 'data'}),
            throwsA(isA<FormatException>()));

        // Test invalid notification JSON
        expect(() => ReminderNotification.fromJson({}),
            throwsA(isA<FormatException>()));
        expect(() => ReminderNotification.fromJson({'invalid': 'data'}),
            throwsA(isA<FormatException>()));

        // Test partial data
        expect(
            () => ReminderSettings.fromJson({
                  'enabled': true,
                  // Missing required fields
                }),
            throwsA(isA<FormatException>()));
      });
    });

    group('Error Handling and Edge Cases Integration', () {
      testWidgets('should handle all validation edge cases comprehensively',
          (tester) async {
        // Test invalid day values
        final invalidDaysSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {0, 8, -1, 15}, // All invalid day values
          respectHolidays: true,
          snoozeMinutes: 15,
          maxSnoozes: 2,
        );

        expect(invalidDaysSettings.validate(),
            contains('Active days must be between 1 (Monday) and 7 (Sunday)'));

        // Test extreme snooze values
        final extremeSnoozeSettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 8, minute: 0),
          clockOutTime: const TimeOfDay(hour: 17, minute: 0),
          activeDays: {1, 2, 3, 4, 5},
          respectHolidays: true,
          snoozeMinutes: -5, // Negative
          maxSnoozes: 100, // Too high
        );

        final validationError = extremeSnoozeSettings.validate();
        expect(validationError, isNotNull);
        expect(
            validationError,
            anyOf([
              contains('Snooze minutes must be between 1 and 60'),
              contains('Maximum snoozes must be between 0 and 5'),
            ]));

        // Test boundary values
        final boundarySettings = ReminderSettings(
          enabled: true,
          clockInTime: const TimeOfDay(hour: 0, minute: 0), // Midnight
          clockOutTime:
              const TimeOfDay(hour: 23, minute: 59), // Almost midnight
          activeDays: {1, 2, 3, 4, 5, 6, 7}, // All days
          respectHolidays: true,
          snoozeMinutes: 60, // Maximum
          maxSnoozes: 5, // Maximum
        );

        expect(boundarySettings.validate(), isNull); // Should be valid
        expect(boundarySettings.workDuration.inHours, 23); // Almost 24 hours
      });

      testWidgets('should handle notification validation edge cases',
          (tester) async {
        // Test notification with empty strings
        final emptyTitleNotification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: '', // Empty
          body: 'Valid body',
          payload: 'valid_payload',
        );

        expect(emptyTitleNotification.validate(),
            contains('title cannot be empty'));

        // Test notification with empty body
        final emptyBodyNotification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: 'Valid title',
          body: '', // Empty
          payload: 'valid_payload',
        );

        expect(
            emptyBodyNotification.validate(), contains('body cannot be empty'));

        // Test notification with negative snooze count
        final negativeSnoozeNotification = ReminderNotification(
          id: 1,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: 'Valid title',
          body: 'Valid body',
          payload: 'valid_payload',
          snoozeCount: -1, // Negative
        );

        expect(negativeSnoozeNotification.validate(),
            contains('Snooze count cannot be negative'));

        // Test notification with negative ID
        final negativeIdNotification = ReminderNotification(
          id: -1, // Negative
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: 'Valid title',
          body: 'Valid body',
          payload: 'valid_payload',
        );

        expect(negativeIdNotification.validate(),
            contains('ID must be non-negative'));
      });
    });
  });
}
