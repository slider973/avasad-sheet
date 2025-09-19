/// Example demonstrating notification content and interaction handling
///
/// This file shows how the enhanced notification system works with:
/// - Professional notification content (Requirements 5.1, 5.2)
/// - Notification tap handling (Requirement 1.5)
/// - Dismissal and snooze logic (Requirements 5.3, 5.4)
/// - Notification grouping (Requirement 5.5)

import 'package:flutter/material.dart';
import '../features/preference/data/models/reminder_notification.dart';
import '../features/preference/data/models/reminder_settings.dart';
import '../enum/reminder_type.dart';

class NotificationInteractionExample {
  /// Example 1: Creating professional notification content
  /// Requirement 5.1: Professional reminder notification messages
  /// Requirement 5.2: Include current time and action needed
  static void demonstrateProfessionalContent() {
    print('=== Professional Notification Content Example ===');

    // Create a clock-in reminder
    final clockInReminder = ReminderNotification.clockIn(
      id: 1000,
      scheduledTime: DateTime(2025, 1, 15, 9, 0), // 9:00 AM
    );

    print('Clock-In Reminder:');
    print('Title: ${clockInReminder.title}');
    print('Body: ${clockInReminder.body}');
    print('Payload: ${clockInReminder.payload}');
    print('');

    // Create a clock-out reminder
    final clockOutReminder = ReminderNotification.clockOut(
      id: 1001,
      scheduledTime: DateTime(2025, 1, 15, 17, 30), // 5:30 PM
    );

    print('Clock-Out Reminder:');
    print('Title: ${clockOutReminder.title}');
    print('Body: ${clockOutReminder.body}');
    print('Payload: ${clockOutReminder.payload}');
    print('');
  }

  /// Example 2: Demonstrating snooze functionality
  /// Requirement 5.4: Snooze functionality with maximum limits
  static void demonstrateSnoozeLogic() {
    print('=== Snooze Functionality Example ===');

    final originalReminder = ReminderNotification.clockIn(
      id: 1000,
      scheduledTime: DateTime(2025, 1, 15, 9, 0),
    );

    print('Original Reminder:');
    print('Title: ${originalReminder.title}');
    print('Snooze Count: ${originalReminder.snoozeCount}');
    print('Can Snooze (max 3): ${originalReminder.canSnooze(3)}');
    print('');

    // Snooze the reminder
    final snoozedReminder =
        originalReminder.snooze(const Duration(minutes: 15));

    print('After First Snooze:');
    print('Title: ${snoozedReminder.title}');
    print('Body: ${snoozedReminder.body}');
    print('Snooze Count: ${snoozedReminder.snoozeCount}');
    print('Scheduled Time: ${snoozedReminder.scheduledTime}');
    print('Can Snooze Again: ${snoozedReminder.canSnooze(3)}');
    print('');

    // Snooze multiple times to demonstrate limits
    var currentReminder = snoozedReminder;
    for (int i = 2; i <= 4; i++) {
      if (currentReminder.canSnooze(3)) {
        currentReminder = currentReminder.snooze(const Duration(minutes: 15));
        print('After Snooze $i:');
        print('Snooze Count: ${currentReminder.snoozeCount}');
        print('Can Snooze Again: ${currentReminder.canSnooze(3)}');
      } else {
        print('Cannot snooze anymore - maximum limit reached');
        break;
      }
    }
    print('');
  }

  /// Example 3: Demonstrating dismissal logic
  /// Requirement 5.3: Notification dismissal logic
  static void demonstrateDismissalLogic() {
    print('=== Dismissal Logic Example ===');

    final reminder = ReminderNotification.clockIn(
      id: 1000,
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
    );

    print('Original Reminder State:');
    print('Is Pending: ${reminder.isPending}');
    print('Is Cancelled: ${reminder.isCancelled}');
    print('Can Snooze: ${reminder.canSnooze(3)}');
    print('');

    // Dismiss the reminder
    final dismissedReminder = reminder.markAsCancelled();

    print('After Dismissal:');
    print('Is Pending: ${dismissedReminder.isPending}');
    print('Is Cancelled: ${dismissedReminder.isCancelled}');
    print('Can Snooze: ${dismissedReminder.canSnooze(3)}');
    print('');
  }

  /// Example 4: Demonstrating notification grouping
  /// Requirement 5.5: Notification grouping to prevent spam
  static void demonstrateNotificationGrouping() {
    print('=== Notification Grouping Example ===');

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    // Create multiple reminders for the same day
    final todayClockIn = ReminderNotification.clockIn(
      id: 1000,
      scheduledTime: DateTime(today.year, today.month, today.day, 9, 0),
    );

    final todayClockOut = ReminderNotification.clockOut(
      id: 1001,
      scheduledTime: DateTime(today.year, today.month, today.day, 17, 0),
    );

    // Create reminders for different day
    final tomorrowClockIn = ReminderNotification.clockIn(
      id: 1002,
      scheduledTime:
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0),
    );

    print('Reminder Unique Keys for Grouping:');
    print('Today Clock-In: ${todayClockIn.uniqueKey}');
    print('Today Clock-Out: ${todayClockOut.uniqueKey}');
    print('Tomorrow Clock-In: ${tomorrowClockIn.uniqueKey}');
    print('');

    // Demonstrate grouping logic
    final reminders = [todayClockIn, todayClockOut, tomorrowClockIn];
    final groupedByDate = <String, List<ReminderNotification>>{};

    for (final reminder in reminders) {
      final dateKey = reminder.uniqueKey.split('_').last; // Extract date part
      groupedByDate.putIfAbsent(dateKey, () => []).add(reminder);
    }

    print('Grouped Reminders:');
    groupedByDate.forEach((date, reminderList) {
      print('Date $date: ${reminderList.length} reminders');
      for (final reminder in reminderList) {
        print(
            '  - ${reminder.type.displayName} at ${_formatTime(reminder.scheduledTime)}');
      }
    });
    print('');
  }

  /// Example 5: Demonstrating notification tap handling
  /// Requirement 1.5: Notification tap handling to open time tracking screen
  static void demonstrateNotificationTapHandling() {
    print('=== Notification Tap Handling Example ===');

    final clockInReminder = ReminderNotification.clockIn(
      id: 1000,
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
    );

    final clockOutReminder = ReminderNotification.clockOut(
      id: 1001,
      scheduledTime: DateTime.now().add(const Duration(hours: 8)),
    );

    print('Notification Payloads for Tap Handling:');
    print('Clock-In Payload: ${clockInReminder.payload}');
    print('Clock-Out Payload: ${clockOutReminder.payload}');
    print('');

    // Simulate handling different payloads
    final payloads = [
      clockInReminder.payload,
      clockOutReminder.payload,
      'snooze_clockIn',
      'dismiss_clockOut',
    ];

    for (final payload in payloads) {
      print('Handling payload: $payload');
      _simulatePayloadHandling(payload);
      print('');
    }
  }

  /// Example 6: Complete notification lifecycle
  static void demonstrateCompleteLifecycle() {
    print('=== Complete Notification Lifecycle Example ===');

    // 1. Create reminder
    var reminder = ReminderNotification.clockIn(
      id: 1000,
      scheduledTime: DateTime.now().add(const Duration(hours: 1)),
    );

    print('1. Created Reminder:');
    print(
        '   State: Pending=${reminder.isPending}, Delivered=${reminder.isDelivered}');
    print('   Content: ${reminder.title}');
    print('');

    // 2. User snoozes
    reminder = reminder.snooze(const Duration(minutes: 15));
    print('2. After Snooze:');
    print('   Snooze Count: ${reminder.snoozeCount}');
    print('   New Time: ${_formatTime(reminder.scheduledTime)}');
    print('   Content: ${reminder.title}');
    print('');

    // 3. Notification delivered
    reminder = reminder.markAsDelivered();
    print('3. After Delivery:');
    print(
        '   State: Pending=${reminder.isPending}, Delivered=${reminder.isDelivered}');
    print('   Can Snooze: ${reminder.canSnooze(3)}');
    print('');

    // 4. Validation
    final validationResult = reminder.validate();
    print('4. Validation Result: ${validationResult ?? "Valid"}');
    print('');
  }

  /// Helper method to simulate payload handling
  static void _simulatePayloadHandling(String payload) {
    switch (payload) {
      case 'clock_in_reminder':
        print('  -> Opening app and navigating to clock-in screen');
        break;
      case 'clock_out_reminder':
        print('  -> Opening app and navigating to clock-out screen');
        break;
      case 'snooze_clockIn':
        print('  -> Snoozing clock-in reminder for 15 minutes');
        break;
      case 'dismiss_clockOut':
        print('  -> Dismissing clock-out reminder');
        break;
      default:
        print('  -> Unknown payload, opening main app screen');
    }
  }

  /// Helper method to format time for display
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  /// Run all examples
  static void runAllExamples() {
    print('🔔 NOTIFICATION CONTENT AND INTERACTION HANDLING EXAMPLES 🔔\n');

    demonstrateProfessionalContent();
    demonstrateSnoozeLogic();
    demonstrateDismissalLogic();
    demonstrateNotificationGrouping();
    demonstrateNotificationTapHandling();
    demonstrateCompleteLifecycle();

    print('✅ All examples completed successfully!');
  }
}

/// Example usage in main function or test
void main() {
  NotificationInteractionExample.runAllExamples();
}
