import 'package:isar/isar.dart';

part 'overtime_configuration.g.dart';

/// Isar model for storing overtime configuration settings
///
/// This model stores all overtime-related configuration including:
/// - Weekend overtime settings
/// - Custom weekend days
/// - Overtime rates for weekend vs weekday
/// - Daily work thresholds
@collection
class OvertimeConfiguration {
  Id id = Isar.autoIncrement;

  /// Whether weekend overtime is enabled
  @Index()
  bool weekendOvertimeEnabled = true;

  /// List of weekend days (1=Monday, 7=Sunday)
  /// Stored as a list of integers
  List<int> weekendDays = [DateTime.saturday, DateTime.sunday];

  /// Overtime rate multiplier for weekend hours (e.g., 1.5 for 150%)
  double weekendOvertimeRate = 1.5;

  /// Overtime rate multiplier for weekday hours (e.g., 1.25 for 125%)
  double weekdayOvertimeRate = 1.25;

  /// Daily work threshold in minutes after which work is considered overtime
  int dailyWorkThresholdMinutes = 480; // 8 hours

  /// Timestamp when this configuration was last updated
  @Index()
  DateTime lastUpdated = DateTime.now();

  /// Version number for configuration schema migrations
  int configVersion = 1;

  /// Optional description or notes about this configuration
  String? description;

  /// Default constructor
  OvertimeConfiguration();

  /// Constructor with all parameters
  OvertimeConfiguration.withValues({
    required this.weekendOvertimeEnabled,
    required this.weekendDays,
    required this.weekendOvertimeRate,
    required this.weekdayOvertimeRate,
    required this.dailyWorkThresholdMinutes,
    this.description,
  }) : lastUpdated = DateTime.now();

  /// Factory constructor for creating default configuration
  factory OvertimeConfiguration.defaultConfig() {
    return OvertimeConfiguration.withValues(
      weekendOvertimeEnabled: true,
      weekendDays: [DateTime.saturday, DateTime.sunday],
      weekendOvertimeRate: 1.5,
      weekdayOvertimeRate: 1.25,
      dailyWorkThresholdMinutes: 480,
      description: 'Default overtime configuration',
    );
  }

  /// Gets the daily work threshold as a Duration
  @ignore
  Duration get dailyWorkThreshold =>
      Duration(minutes: dailyWorkThresholdMinutes);

  /// Sets the daily work threshold from a Duration
  @ignore
  set dailyWorkThreshold(Duration duration) {
    dailyWorkThresholdMinutes = duration.inMinutes;
    lastUpdated = DateTime.now();
  }

  /// Validates the configuration values
  ///
  /// Throws [ArgumentError] if any values are invalid
  void validate() {
    // Validate weekend days
    if (weekendDays.isEmpty) {
      throw ArgumentError('Weekend days cannot be empty');
    }

    for (final day in weekendDays) {
      if (day < 1 || day > 7) {
        throw ArgumentError(
            'Invalid weekend day: $day. Must be between 1 (Monday) and 7 (Sunday)');
      }
    }

    // Check for duplicates
    final uniqueDays = weekendDays.toSet();
    if (uniqueDays.length != weekendDays.length) {
      throw ArgumentError('Duplicate weekend days are not allowed');
    }

    // Ensure at least one working day remains
    if (weekendDays.length >= 7) {
      throw ArgumentError(
          'Cannot set all days as weekend days. At least one working day must remain');
    }

    // Validate overtime rates
    if (weekendOvertimeRate < 1.0) {
      throw ArgumentError('Weekend overtime rate must be at least 1.0 (100%)');
    }

    if (weekdayOvertimeRate < 1.0) {
      throw ArgumentError('Weekday overtime rate must be at least 1.0 (100%)');
    }

    if (weekendOvertimeRate > 10.0) {
      throw ArgumentError('Weekend overtime rate cannot exceed 10.0 (1000%)');
    }

    if (weekdayOvertimeRate > 10.0) {
      throw ArgumentError('Weekday overtime rate cannot exceed 10.0 (1000%)');
    }

    // Validate daily work threshold
    if (dailyWorkThresholdMinutes < 60) {
      throw ArgumentError('Daily work threshold must be at least 1 hour');
    }

    if (dailyWorkThresholdMinutes > 1440) {
      throw ArgumentError('Daily work threshold cannot exceed 24 hours');
    }
  }

  /// Updates the lastUpdated timestamp
  void touch() {
    lastUpdated = DateTime.now();
  }

  /// Creates a copy of this configuration with optional parameter overrides
  OvertimeConfiguration copyWith({
    bool? weekendOvertimeEnabled,
    List<int>? weekendDays,
    double? weekendOvertimeRate,
    double? weekdayOvertimeRate,
    int? dailyWorkThresholdMinutes,
    String? description,
  }) {
    return OvertimeConfiguration.withValues(
      weekendOvertimeEnabled:
          weekendOvertimeEnabled ?? this.weekendOvertimeEnabled,
      weekendDays: weekendDays ?? List.from(this.weekendDays),
      weekendOvertimeRate: weekendOvertimeRate ?? this.weekendOvertimeRate,
      weekdayOvertimeRate: weekdayOvertimeRate ?? this.weekdayOvertimeRate,
      dailyWorkThresholdMinutes:
          dailyWorkThresholdMinutes ?? this.dailyWorkThresholdMinutes,
      description: description ?? this.description,
    );
  }

  /// Converts this configuration to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weekendOvertimeEnabled': weekendOvertimeEnabled,
      'weekendDays': weekendDays,
      'weekendOvertimeRate': weekendOvertimeRate,
      'weekdayOvertimeRate': weekdayOvertimeRate,
      'dailyWorkThresholdMinutes': dailyWorkThresholdMinutes,
      'lastUpdated': lastUpdated.toIso8601String(),
      'configVersion': configVersion,
      'description': description,
    };
  }

  /// Creates an OvertimeConfiguration from a Map
  factory OvertimeConfiguration.fromMap(Map<String, dynamic> map) {
    final config = OvertimeConfiguration();
    config.weekendOvertimeEnabled = map['weekendOvertimeEnabled'] ?? true;
    config.weekendDays = List<int>.from(
        map['weekendDays'] ?? [DateTime.saturday, DateTime.sunday]);
    config.weekendOvertimeRate = (map['weekendOvertimeRate'] ?? 1.5).toDouble();
    config.weekdayOvertimeRate =
        (map['weekdayOvertimeRate'] ?? 1.25).toDouble();
    config.dailyWorkThresholdMinutes = map['dailyWorkThresholdMinutes'] ?? 480;
    config.lastUpdated = map['lastUpdated'] != null
        ? DateTime.parse(map['lastUpdated'])
        : DateTime.now();
    config.configVersion = map['configVersion'] ?? 1;
    config.description = map['description'];
    return config;
  }

  @override
  String toString() {
    return 'OvertimeConfiguration{'
        'id: $id, '
        'weekendOvertimeEnabled: $weekendOvertimeEnabled, '
        'weekendDays: $weekendDays, '
        'weekendOvertimeRate: $weekendOvertimeRate, '
        'weekdayOvertimeRate: $weekdayOvertimeRate, '
        'dailyWorkThresholdMinutes: $dailyWorkThresholdMinutes, '
        'lastUpdated: $lastUpdated, '
        'configVersion: $configVersion, '
        'description: $description'
        '}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OvertimeConfiguration) return false;

    return weekendOvertimeEnabled == other.weekendOvertimeEnabled &&
        weekendDays.length == other.weekendDays.length &&
        weekendDays.every((day) => other.weekendDays.contains(day)) &&
        weekendOvertimeRate == other.weekendOvertimeRate &&
        weekdayOvertimeRate == other.weekdayOvertimeRate &&
        dailyWorkThresholdMinutes == other.dailyWorkThresholdMinutes &&
        configVersion == other.configVersion &&
        description == other.description;
  }

  @override
  int get hashCode {
    return Object.hash(
      weekendOvertimeEnabled,
      Object.hashAll(weekendDays),
      weekendOvertimeRate,
      weekdayOvertimeRate,
      dailyWorkThresholdMinutes,
      configVersion,
      description,
    );
  }
}
