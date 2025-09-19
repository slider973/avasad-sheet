import 'package:equatable/equatable.dart';
import '../../../../enum/reminder_type.dart';

/// Model representing a scheduled reminder notification
class ReminderNotification extends Equatable {
  /// Unique identifier for the notification
  final int id;

  /// Type of reminder (clock in or clock out)
  final ReminderType type;

  /// When the notification is scheduled to be delivered
  final DateTime scheduledTime;

  /// Notification title
  final String title;

  /// Notification body message
  final String body;

  /// Payload data for notification interaction
  final String payload;

  /// Current snooze count for this notification
  final int snoozeCount;

  /// Whether this notification has been delivered
  final bool isDelivered;

  /// Whether this notification has been cancelled
  final bool isCancelled;

  const ReminderNotification({
    required this.id,
    required this.type,
    required this.scheduledTime,
    required this.title,
    required this.body,
    required this.payload,
    this.snoozeCount = 0,
    this.isDelivered = false,
    this.isCancelled = false,
  });

  /// Creates a clock-in reminder notification with professional content
  /// Requirements: 5.1, 5.2 - Professional tone and current time information
  factory ReminderNotification.clockIn({
    required int id,
    required DateTime scheduledTime,
    int snoozeCount = 0,
  }) {
    final timeString = _formatTime(scheduledTime);
    final currentTime = _formatTime(DateTime.now());

    String title;
    String body;

    if (snoozeCount > 0) {
      title = 'Work Reminder (Snoozed)';
      body = 'Time to clock in and start your workday.\n'
          'Current time: $currentTime • Scheduled: $timeString\n'
          'This reminder has been snoozed ${snoozeCount} time${snoozeCount > 1 ? 's' : ''}.';
    } else {
      title = 'Good Morning!';
      body = 'Time to clock in and start your workday.\n'
          'Current time: $currentTime • Scheduled: $timeString\n'
          'Tap to open the app and begin tracking your time.';
    }

    return ReminderNotification(
      id: id,
      type: ReminderType.clockIn,
      scheduledTime: scheduledTime,
      title: title,
      body: body,
      payload: 'clock_in_reminder',
      snoozeCount: snoozeCount,
    );
  }

  /// Creates a clock-out reminder notification with professional content
  /// Requirements: 5.1, 5.2 - Professional tone and current time information
  factory ReminderNotification.clockOut({
    required int id,
    required DateTime scheduledTime,
    int snoozeCount = 0,
  }) {
    final timeString = _formatTime(scheduledTime);
    final currentTime = _formatTime(DateTime.now());

    String title;
    String body;

    if (snoozeCount > 0) {
      title = 'Work Reminder (Snoozed)';
      body = 'Time to clock out and end your workday.\n'
          'Current time: $currentTime • Scheduled: $timeString\n'
          'This reminder has been snoozed ${snoozeCount} time${snoozeCount > 1 ? 's' : ''}.';
    } else {
      title = 'End of Workday';
      body = 'Time to clock out and wrap up your day.\n'
          'Current time: $currentTime • Scheduled: $timeString\n'
          'Tap to open the app and complete your time tracking.';
    }

    return ReminderNotification(
      id: id,
      type: ReminderType.clockOut,
      scheduledTime: scheduledTime,
      title: title,
      body: body,
      payload: 'clock_out_reminder',
      snoozeCount: snoozeCount,
    );
  }

  /// Creates a copy with updated values
  ReminderNotification copyWith({
    int? id,
    ReminderType? type,
    DateTime? scheduledTime,
    String? title,
    String? body,
    String? payload,
    int? snoozeCount,
    bool? isDelivered,
    bool? isCancelled,
  }) {
    return ReminderNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      snoozeCount: snoozeCount ?? this.snoozeCount,
      isDelivered: isDelivered ?? this.isDelivered,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  /// Creates a snoozed version of this notification with professional content
  /// Requirements: 5.4 - Snooze functionality with professional messaging
  ReminderNotification snooze(Duration snoozeDuration) {
    final newScheduledTime = DateTime.now().add(snoozeDuration);
    final newSnoozeCount = snoozeCount + 1;

    // Create a new notification with updated content using the factory methods
    switch (type) {
      case ReminderType.clockIn:
        return ReminderNotification.clockIn(
          id: id,
          scheduledTime: newScheduledTime,
          snoozeCount: newSnoozeCount,
        );
      case ReminderType.clockOut:
        return ReminderNotification.clockOut(
          id: id,
          scheduledTime: newScheduledTime,
          snoozeCount: newSnoozeCount,
        );
    }
  }

  /// Marks the notification as delivered
  ReminderNotification markAsDelivered() {
    return copyWith(isDelivered: true);
  }

  /// Marks the notification as cancelled
  ReminderNotification markAsCancelled() {
    return copyWith(isCancelled: true);
  }

  /// Checks if this notification can be snoozed
  bool canSnooze(int maxSnoozes) {
    return snoozeCount < maxSnoozes && !isDelivered && !isCancelled;
  }

  /// Checks if this notification is still pending
  bool get isPending {
    return !isDelivered &&
        !isCancelled &&
        scheduledTime.isAfter(DateTime.now());
  }

  /// Checks if this notification is overdue
  bool get isOverdue {
    return !isDelivered &&
        !isCancelled &&
        scheduledTime.isBefore(DateTime.now());
  }

  /// Gets a unique key for this notification type and date
  String get uniqueKey {
    final dateKey =
        '${scheduledTime.year}-${scheduledTime.month}-${scheduledTime.day}';
    return '${type.name}_$dateKey';
  }

  /// Validates the notification data
  String? validate() {
    if (id < 0) {
      return 'Notification ID must be non-negative';
    }

    if (title.isEmpty) {
      return 'Notification title cannot be empty';
    }

    if (body.isEmpty) {
      return 'Notification body cannot be empty';
    }

    if (snoozeCount < 0) {
      return 'Snooze count cannot be negative';
    }

    return null; // Valid
  }

  /// Converts to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toJson(),
      'scheduledTime': scheduledTime.toIso8601String(),
      'title': title,
      'body': body,
      'payload': payload,
      'snoozeCount': snoozeCount,
      'isDelivered': isDelivered,
      'isCancelled': isCancelled,
    };
  }

  /// Creates ReminderNotification from JSON
  factory ReminderNotification.fromJson(Map<String, dynamic> json) {
    try {
      return ReminderNotification(
        id: json['id'] as int,
        type: ReminderType.fromJson(json['type'] as String),
        scheduledTime: DateTime.parse(json['scheduledTime'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        payload: json['payload'] as String,
        snoozeCount: json['snoozeCount'] as int? ?? 0,
        isDelivered: json['isDelivered'] as bool? ?? false,
        isCancelled: json['isCancelled'] as bool? ?? false,
      );
    } catch (e) {
      throw FormatException('Invalid ReminderNotification JSON: $e');
    }
  }

  /// Formats time for display in notifications
  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  @override
  List<Object?> get props => [
        id,
        type,
        scheduledTime,
        title,
        body,
        payload,
        snoozeCount,
        isDelivered,
        isCancelled,
      ];

  @override
  String toString() {
    return 'ReminderNotification('
        'id: $id, '
        'type: $type, '
        'scheduledTime: $scheduledTime, '
        'title: $title, '
        'snoozeCount: $snoozeCount, '
        'isDelivered: $isDelivered, '
        'isCancelled: $isCancelled'
        ')';
  }
}
