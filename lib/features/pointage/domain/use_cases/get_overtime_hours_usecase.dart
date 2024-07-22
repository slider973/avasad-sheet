class GetOvertimeHoursUseCase {
  Future<Duration> execute(Duration weeklyWorkTime, Duration weeklyTarget) async {
    return weeklyWorkTime > weeklyTarget ? weeklyWorkTime - weeklyTarget : Duration.zero;
  }
}