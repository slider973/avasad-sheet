/// Enum representing the type of reminder notification
enum ReminderType {
  /// Reminder to clock in at the start of work
  clockIn,

  /// Reminder to clock out at the end of work
  clockOut;

  /// Returns a human-readable string representation of the reminder type
  String get displayName {
    switch (this) {
      case ReminderType.clockIn:
        return 'Clock In';
      case ReminderType.clockOut:
        return 'Clock Out';
    }
  }

  /// Returns the action verb for the reminder type
  String get actionVerb {
    switch (this) {
      case ReminderType.clockIn:
        return 'clock in';
      case ReminderType.clockOut:
        return 'clock out';
    }
  }

  /// Returns the notification title for the reminder type
  String get notificationTitle {
    switch (this) {
      case ReminderType.clockIn:
        return 'Time to Clock In';
      case ReminderType.clockOut:
        return 'Time to Clock Out';
    }
  }

  /// Creates a ReminderType from a string value
  static ReminderType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'clockin':
      case 'clock_in':
        return ReminderType.clockIn;
      case 'clockout':
      case 'clock_out':
        return ReminderType.clockOut;
      default:
        throw ArgumentError('Invalid reminder type: $value');
    }
  }

  /// Converts the enum to a string for serialization
  String toJson() => name;

  /// Creates a ReminderType from JSON
  static ReminderType fromJson(String json) => ReminderType.values.byName(json);
}
