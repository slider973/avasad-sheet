part of 'team_timesheet_bloc.dart';

class TeamTimesheetState extends Equatable {
  final List<EmployeeTimesheetEntry> entries;
  final bool isLoading;

  const TeamTimesheetState({
    this.entries = const [],
    this.isLoading = true,
  });

  TeamTimesheetState copyWith({
    List<EmployeeTimesheetEntry>? entries,
    bool? isLoading,
  }) {
    return TeamTimesheetState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [entries, isLoading];
}
