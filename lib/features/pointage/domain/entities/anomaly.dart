class Anomaly {
  final String id;
  final String message;
  final DateTime date;
  final String detectorId;
  final bool isCompensated;
  final String? weekReference;
  final String? compensationReason;

  Anomaly({
    required this.id,
    required this.message,
    required this.date,
    required this.detectorId,
    this.isCompensated = false,
    this.weekReference,
    this.compensationReason,
  });

  Anomaly copyWith({
    String? id,
    String? message,
    DateTime? date,
    String? detectorId,
    bool? isCompensated,
    String? weekReference,
    String? compensationReason,
  }) {
    return Anomaly(
      id: id ?? this.id,
      message: message ?? this.message,
      date: date ?? this.date,
      detectorId: detectorId ?? this.detectorId,
      isCompensated: isCompensated ?? this.isCompensated,
      weekReference: weekReference ?? this.weekReference,
      compensationReason: compensationReason ?? this.compensationReason,
    );
  }

  @override
  String toString() {
    return 'Anomaly(id: $id, message: $message, date: $date, detectorId: $detectorId, isCompensated: $isCompensated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Anomaly && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}