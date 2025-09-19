import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import '../lib/features/preference/data/models/reminder_notification.dart';
import '../lib/features/preference/data/models/reminder_settings.dart';
import '../lib/enum/reminder_type.dart';

void main() {
  group('Notification Content and Interaction Handling', () {
    group('Professional Notification Content', () {
      test('should create professional clock-in reminder content', () {
        // Requirement 5.1: Professional reminder notification messages
        final scheduledTime = DateTime(2025, 1, 15, 9, 0); // 9:00 AM
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: scheduledTime,
        );

        expect(reminder.title, equals('Good Morning!'));
        expect(
            reminder.body, contains('Time to clock in and start your workday'));
        expect(reminder.body, contains('Current time:'));
        expect(reminder.body, contains('Scheduled: 9:00 AM'));
        expect(reminder.body, contains('Tap to open the app'));
      });

      test('should create professional clock-out reminder content', () {
        // Requirement 5.1: Professional reminder notification messages
        final scheduledTime = DateTime(2025, 1, 15, 17, 0); // 5:00 PM
        final reminder = ReminderNotification.clockOut(
          id: 1001,
          scheduledTime: scheduledTime,
        );

        expect(reminder.title, equals('End of Workday'));
        expect(
            reminder.body, contains('Time to clock out and wrap up your day'));
        expect(reminder.body, contains('Current time:'));
        expect(reminder.body, contains('Scheduled: 5:00 PM'));
        expect(reminder.body, contains('complete your time tracking'));
      });

      test('should include current time and action needed in notification', () {
        // Requirement 5.2: Include current time and action needed
        final scheduledTime = DateTime(2025, 1, 15, 9, 0);
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: scheduledTime,
        );

        // Should include both current time and scheduled time
        expect(reminder.body, contains('Current time:'));
        expect(reminder.body, contains('Scheduled:'));
        expect(reminder.body, contains('clock in'));
      });

      test('should create professional snoozed notification content', () {
        // Requirement 5.4: Professional snooze messaging
        final scheduledTime = DateTime(2025, 1, 15, 9, 0);
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: scheduledTime,
          snoozeCount: 2,
        );

        expect(reminder.title, equals('Work Reminder (Snoozed)'));
        expect(reminder.body, contains('snoozed 2 times'));
        expect(reminder.snoozeCount, equals(2));
      });
    });

    group('Notification Interaction Handling', () {
      test('should create proper payload for clock-in reminder', () {
        // Requirement 1.5: Notification tap handling to open time tracking screen
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime(2025, 1, 15, 9, 0),
        );

        expect(reminder.payload, equals('clock_in_reminder'));
        expect(reminder.type, equals(ReminderType.clockIn));
      });

      test('should create proper payload for clock-out reminder', () {
        // Requirement 1.5: Notification tap handling to open time tracking screen
        final reminder = ReminderNotification.clockOut(
          id: 1001,
          scheduledTime: DateTime(2025, 1, 15, 17, 0),
        );

        expect(reminder.payload, equals('clock_out_reminder'));
        expect(reminder.type, equals(ReminderType.clockOut));
      });

      test('should handle notification dismissal state', () {
        // Requirement 5.3: Notification dismissal logic
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );

        final dismissedReminder = reminder.markAsCancelled();

        expect(dismissedReminder.isCancelled, isTrue);
        expect(dismissedReminder.isPending, isFalse);
      });
    });

    group('Notification Grouping Support', () {
      test('should provide unique keys for grouping', () {
        // Requirement 5.5: Notification grouping to prevent spam
        final clockInReminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime(2025, 1, 15, 9, 0),
        );

        final clockOutReminder = ReminderNotification.clockOut(
          id: 1001,
          scheduledTime: DateTime(2025, 1, 15, 17, 0),
        );

        // Should have different unique keys for different types
        expect(clockInReminder.uniqueKey,
            isNot(equals(clockOutReminder.uniqueKey)));
        expect(clockInReminder.uniqueKey, contains('clockIn'));
        expect(clockOutReminder.uniqueKey, contains('clockOut'));
      });

      test('should group notifications by date', () {
        // Requirement 5.5: Group notifications by date
        final reminder1 = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime(2025, 1, 15, 9, 0),
        );

        final reminder2 = ReminderNotification.clockIn(
          id: 1002,
          scheduledTime: DateTime(2025, 1, 16, 9, 0), // Different date
        );

        // Same type, different dates should have different keys
        expect(reminder1.uniqueKey, isNot(equals(reminder2.uniqueKey)));
        expect(reminder1.uniqueKey, contains('2025-1-15'));
        expect(reminder2.uniqueKey, contains('2025-1-16'));
      });
    });

    group('Snooze Functionality', () {
      test('should create snoozed notification with updated content', () {
        // Requirement 5.4: Snooze functionality with maximum limits
        final originalReminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime(2025, 1, 15, 9, 0),
        );

        final snoozedReminder =
            originalReminder.snooze(const Duration(minutes: 15));

        expect(snoozedReminder.snoozeCount, equals(1));
        expect(snoozedReminder.title, equals('Work Reminder (Snoozed)'));
        expect(snoozedReminder.body, contains('snoozed 1 time'));
        expect(snoozedReminder.scheduledTime.isAfter(DateTime.now()), isTrue);
      });

      test('should respect maximum snooze limits', () {
        // Requirement 5.4: Maximum snooze limits
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now(),
          snoozeCount: 3, // At maximum
        );

        expect(reminder.canSnooze(3), isFalse);
        expect(reminder.canSnooze(5), isTrue);
      });

      test('should not allow snoozing cancelled notifications', () {
        // Requirement 5.3: Cannot snooze dismissed notifications
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now(),
        ).markAsCancelled();

        expect(reminder.canSnooze(3), isFalse);
      });

      test('should not allow snoozing delivered notifications', () {
        // Requirement 5.3: Cannot snooze delivered notifications
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now(),
        ).markAsDelivered();

        expect(reminder.canSnooze(3), isFalse);
      });
    });

    group('Notification Validation', () {
      test('should validate notification content', () {
        final validReminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(validReminder.validate(), isNull);
      });

      test('should detect invalid notification ID', () {
        final invalidReminder = ReminderNotification(
          id: -1, // Invalid ID
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: 'Valid Title',
          body: 'Valid Body',
          payload: 'test',
        );

        final validationError = invalidReminder.validate();
        expect(validationError, isNotNull);
        expect(validationError, contains('ID must be non-negative'));
      });

      test('should detect empty notification title', () {
        final invalidReminder = ReminderNotification(
          id: 1000,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: '', // Empty title
          body: 'Valid Body',
          payload: 'test',
        );

        final validationError = invalidReminder.validate();
        expect(validationError, isNotNull);
        expect(validationError, contains('title cannot be empty'));
      });

      test('should detect empty notification body', () {
        final invalidReminder = ReminderNotification(
          id: 1000,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: 'Valid Title',
          body: '', // Empty body
          payload: 'test',
        );

        final validationError = invalidReminder.validate();
        expect(validationError, isNotNull);
        expect(validationError, contains('body cannot be empty'));
      });

      test('should detect negative snooze count', () {
        final invalidReminder = ReminderNotification(
          id: 1000,
          type: ReminderType.clockIn,
          scheduledTime: DateTime.now(),
          title: 'Valid Title',
          body: 'Valid Body',
          payload: 'test',
          snoozeCount: -1, // Invalid snooze count
        );

        final validationError = invalidReminder.validate();
        expect(validationError, isNotNull);
        expect(validationError, contains('Snooze count cannot be negative'));
      });
    });

    group('Notification State Management', () {
      test('should track notification states correctly', () {
        final reminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now().add(const Duration(hours: 1)),
        );

        // Initial state
        expect(reminder.isPending, isTrue);
        expect(reminder.isOverdue, isFalse);
        expect(reminder.isDelivered, isFalse);
        expect(reminder.isCancelled, isFalse);

        // After delivery
        final deliveredReminder = reminder.markAsDelivered();
        expect(deliveredReminder.isDelivered, isTrue);
        expect(deliveredReminder.isPending, isFalse);

        // After cancellation
        final cancelledReminder = reminder.markAsCancelled();
        expect(cancelledReminder.isCancelled, isTrue);
        expect(cancelledReminder.isPending, isFalse);
      });

      test('should detect overdue notifications', () {
        final pastReminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime.now().subtract(const Duration(hours: 1)),
        );

        expect(pastReminder.isOverdue, isTrue);
        expect(pastReminder.isPending, isFalse);
      });
    });

    group('Professional Time Formatting', () {
      test('should format AM times correctly', () {
        final morningReminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime(2025, 1, 15, 9, 30), // 9:30 AM
        );

        expect(morningReminder.body, contains('9:30 AM'));
      });

      test('should format PM times correctly', () {
        final eveningReminder = ReminderNotification.clockOut(
          id: 1001,
          scheduledTime: DateTime(2025, 1, 15, 17, 45), // 5:45 PM
        );

        expect(eveningReminder.body, contains('5:45 PM'));
      });

      test('should format noon correctly', () {
        final noonReminder = ReminderNotification.clockOut(
          id: 1001,
          scheduledTime: DateTime(2025, 1, 15, 12, 0), // 12:00 PM
        );

        expect(noonReminder.body, contains('12:00 PM'));
      });

      test('should format midnight correctly', () {
        final midnightReminder = ReminderNotification.clockIn(
          id: 1000,
          scheduledTime: DateTime(2025, 1, 15, 0, 0), // 12:00 AM
        );

        expect(midnightReminder.body, contains('12:00 AM'));
      });
    });
  });
}
