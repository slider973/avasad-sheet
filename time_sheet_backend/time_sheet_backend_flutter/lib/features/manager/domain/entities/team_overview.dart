import 'package:equatable/equatable.dart';

import 'team_member_status.dart';

/// Vue d'ensemble de l'équipe pour le tableau de bord manager.
class TeamOverview extends Equatable {
  final List<TeamMemberStatus> members;
  final int pendingValidations;
  final int pendingExpenses;
  final int teamAnomalies;

  const TeamOverview({
    required this.members,
    required this.pendingValidations,
    required this.pendingExpenses,
    required this.teamAnomalies,
  });

  int get presentCount => members.where((m) => m.isPresentToday).length;

  int get absentCount => members.where((m) => m.hasAbsence).length;

  @override
  List<Object?> get props => [
        members,
        pendingValidations,
        pendingExpenses,
        teamAnomalies,
      ];
}
