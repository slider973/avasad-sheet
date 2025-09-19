import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Model representing user's reminder notification settings
class ReminderSettings extends Equatable {
  /// Whether reminder notifications are enabled
  final bool enabled;

  /// Time for clock-in reminder (e.g., 8:00 AM)
  final TimeOfDay clockInTime;

  /// Time for clock-out reminder (e.g., 5:00 PM)
  final TimeOfDay clockOutTime;

  /// Set of active days (1-7, where 1=Monday, 7=Sunday)
  final Set<int> activeDays;

  /// Whether to respect holidays and not send reminders
  final bool respectHolidays;

  /// Number of minutes to snooze a reminder
  final int snoozeMinutes;

  /// Maximum number of snoozes allowed per reminder
  final int maxSnoozes;

  const ReminderSettings({
    required this.enabled,
    required this.clockInTime,
    required this.clockOutTime,
    required this.activeDays,
    required this.respectHolidays,
    required this.snoozeMinutes,
    required this.maxSnoozes,
  });

  /// Default reminder settings (disabled by default as per requirements)
  static ReminderSettings get defaultSettings => ReminderSettings(
        enabled: false, // Disabled by default per requirement 1.1
        clockInTime: const TimeOfDay(hour: 8, minute: 0), // 8:00 AM
        clockOutTime: const TimeOfDay(hour: 17, minute: 0), // 5:00 PM
        activeDays: {1, 2, 3, 4, 5}, // Monday to Friday
        respectHolidays: true,
        snoozeMinutes: 15,
        maxSnoozes: 2,
      );

  /// Creates a copy of this settings with updated values
  ReminderSettings copyWith({
    bool? enabled,
    TimeOfDay? clockInTime,
    TimeOfDay? clockOutTime,
    Set<int>? activeDays,
    bool? respectHolidays,
    int? snoozeMinutes,
    int? maxSnoozes,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      clockInTime: clockInTime ?? this.clockInTime,
      clockOutTime: clockOutTime ?? this.clockOutTime,
      activeDays: activeDays ?? this.activeDays,
      respectHolidays: respectHolidays ?? this.respectHolidays,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      maxSnoozes: maxSnoozes ?? this.maxSnoozes,
    );
  }

  /// Validates the reminder settings configuration
  /// Returns null if valid, error message if invalid
  String? validate() {
    // Validate active days
    if (activeDays.isEmpty) {
      return 'At least one active day must be selected';
    }

    if (activeDays.any((day) => day < 1 || day > 7)) {
      return 'Active days must be between 1 (Monday) and 7 (Sunday)';
    }

    // Validate clock-out time is after clock-in time (requirement 2.4)
    final clockInMinutes = clockInTime.hour * 60 + clockInTime.minute;
    final clockOutMinutes = clockOutTime.hour * 60 + clockOutTime.minute;

    if (clockOutMinutes <= clockInMinutes) {
      return 'Clock-out time must be after clock-in time';
    }

    // Validate snooze settings
    if (snoozeMinutes < 1 || snoozeMinutes > 60) {
      return 'Snooze minutes must be between 1 and 60';
    }

    if (maxSnoozes < 0 || maxSnoozes > 5) {
      return 'Maximum snoozes must be between 0 and 5';
    }

    return null; // Valid configuration
  }

  /// Checks if reminders should be active on the given day
  /// [weekday] should be 1-7 where 1=Monday, 7=Sunday
  bool isActiveOnDay(int weekday) {
    return enabled && activeDays.contains(weekday);
  }

  /// Checks if the current time configuration allows for valid reminders
  bool get hasValidTimeConfiguration {
    return validate() == null;
  }

  /// Gets the duration between clock-in and clock-out times
  Duration get workDuration {
    final clockInMinutes = clockInTime.hour * 60 + clockInTime.minute;
    final clockOutMinutes = clockOutTime.hour * 60 + clockOutTime.minute;
    return Duration(minutes: clockOutMinutes - clockInMinutes);
  }

  /// Converts to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'clockInTime': {
        'hour': clockInTime.hour,
        'minute': clockInTime.minute,
      },
      'clockOutTime': {
        'hour': clockOutTime.hour,
        'minute': clockOutTime.minute,
      },
      'activeDays': activeDays.toList(),
      'respectHolidays': respectHolidays,
      'snoozeMinutes': snoozeMinutes,
      'maxSnoozes': maxSnoozes,
    };
  }

  /// Creates ReminderSettings from JSON
  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    try {
      final clockInData = json['clockInTime'] as Map<String, dynamic>;
      final clockOutData = json['clockOutTime'] as Map<String, dynamic>;

      return ReminderSettings(
        enabled: json['enabled'] as bool? ?? false,
        clockInTime: TimeOfDay(
          hour: clockInData['hour'] as int,
          minute: clockInData['minute'] as int,
        ),
        clockOutTime: TimeOfDay(
          hour: clockOutData['hour'] as int,
          minute: clockOutData['minute'] as int,
        ),
        activeDays:
            (json['activeDays'] as List<dynamic>).map((e) => e as int).toSet(),
        respectHolidays: json['respectHolidays'] as bool? ?? true,
        snoozeMinutes: json['snoozeMinutes'] as int? ?? 15,
        maxSnoozes: json['maxSnoozes'] as int? ?? 2,
      );
    } catch (e) {
      throw FormatException('Invalid ReminderSettings JSON: $e');
    }
  }

  @override
  List<Object?> get props => [
        enabled,
        clockInTime,
        clockOutTime,
        activeDays,
        respectHolidays,
        snoozeMinutes,
        maxSnoozes,
      ];

  @override
  String toString() {
    return 'ReminderSettings('
        'enabled: $enabled, '
        'clockInTime: ${clockInTime.hour}:${clockInTime.minute.toString().padLeft(2, '0')}, '
        'clockOutTime: ${clockOutTime.hour}:${clockOutTime.minute.toString().padLeft(2, '0')}, '
        'activeDays: $activeDays, '
        'respectHolidays: $respectHolidays, '
        'snoozeMinutes: $snoozeMinutes, '
        'maxSnoozes: $maxSnoozes'
        ')';
  }
}
