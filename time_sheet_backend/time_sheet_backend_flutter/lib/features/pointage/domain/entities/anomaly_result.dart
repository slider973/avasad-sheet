import '../value_objects/anomaly_type.dart';
import '../value_objects/anomaly_severity.dart';

class AnomalyResult {
  final String ruleId;
  final String ruleName;
  final AnomalyType type;
  final AnomalySeverity severity;
  final String description;
  final DateTime detectedDate;
  final String timesheetEntryId;
  final Map<String, dynamic> metadata;

  const AnomalyResult({
    required this.ruleId,
    required this.ruleName,
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedDate,
    required this.timesheetEntryId,
    this.metadata = const {},
  });

  AnomalyResult copyWith({
    String? ruleId,
    String? ruleName,
    AnomalyType? type,
    AnomalySeverity? severity,
    String? description,
    DateTime? detectedDate,
    String? timesheetEntryId,
    Map<String, dynamic>? metadata,
  }) {
    return AnomalyResult(
      ruleId: ruleId ?? this.ruleId,
      ruleName: ruleName ?? this.ruleName,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      detectedDate: detectedDate ?? this.detectedDate,
      timesheetEntryId: timesheetEntryId ?? this.timesheetEntryId,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnomalyResult &&
        other.ruleId == ruleId &&
        other.timesheetEntryId == timesheetEntryId &&
        other.detectedDate == detectedDate;
  }

  @override
  int get hashCode {
    return ruleId.hashCode ^
        timesheetEntryId.hashCode ^
        detectedDate.hashCode;
  }

  @override
  String toString() {
    return 'AnomalyResult{ruleId: $ruleId, type: $type, severity: $severity, description: $description}';
  }
}