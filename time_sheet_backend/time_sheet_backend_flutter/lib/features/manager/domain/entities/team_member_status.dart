import 'package:equatable/equatable.dart';

/// Statut journalier d'un membre de l'équipe du manager.
class TeamMemberStatus extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final bool isPresentToday;
  final String? lastClockIn;
  final bool hasAbsence;
  final String? absenceType;

  const TeamMemberStatus({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.isPresentToday = false,
    this.lastClockIn,
    this.hasAbsence = false,
    this.absenceType,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        isPresentToday,
        lastClockIn,
        hasAbsence,
        absenceType,
      ];
}
