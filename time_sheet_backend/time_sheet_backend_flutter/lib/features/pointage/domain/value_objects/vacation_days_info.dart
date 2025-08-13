class VacationDaysInfo {
  final int currentYearTotal;
  final int lastYearRemaining;
  final int usedDays;
  final int remainingTotal;

  const VacationDaysInfo({
    required this.currentYearTotal,
    required this.lastYearRemaining,
    required this.usedDays,
    required this.remainingTotal,
  });

  VacationDaysInfo copyWith({
    int? currentYearTotal,
    int? lastYearRemaining,
    int? usedDays,
    int? remainingTotal,
  }) {
    return VacationDaysInfo(
      currentYearTotal: currentYearTotal ?? this.currentYearTotal,
      lastYearRemaining: lastYearRemaining ?? this.lastYearRemaining,
      usedDays: usedDays ?? this.usedDays,
      remainingTotal: remainingTotal ?? this.remainingTotal,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VacationDaysInfo &&
        other.currentYearTotal == currentYearTotal &&
        other.lastYearRemaining == lastYearRemaining &&
        other.usedDays == usedDays &&
        other.remainingTotal == remainingTotal;
  }

  @override
  int get hashCode {
    return currentYearTotal.hashCode ^
        lastYearRemaining.hashCode ^
        usedDays.hashCode ^
        remainingTotal.hashCode;
  }
}