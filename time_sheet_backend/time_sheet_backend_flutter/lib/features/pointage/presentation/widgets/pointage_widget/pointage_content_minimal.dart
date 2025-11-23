import 'package:flutter/material.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/vacation_days_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'pointage_layout.dart';
import 'pointage_fab.dart';

/// Widget de contenu pointage minimal - pour TabView et intégrations serrées
/// Version ultra-épurée sans Scaffold pour éviter les espacements indésirables
class PointageContentMinimal extends StatelessWidget {
  final String etatActuel;
  final DateTime? dernierPointage;
  final DateTime selectedDate;
  final double progression;
  final List<Map<String, dynamic>> pointages;
  final VoidCallback onActionPointage;
  final Function(Map<String, dynamic>) onModifierPointage;
  final Function(DateTime, DateTime, String, AbsenceType, String, String,
      TimeOfDay?, TimeOfDay?) onSignalerAbsencePeriode;
  final VoidCallback onDeleteEntry;
  final Duration totalDayHours;
  final String monthlyHoursStatus;
  final String? absenceReason;
  final AbsenceEntity? absence;
  final Duration totalBreakTime;
  final Duration weeklyWorkTime;
  final Duration weeklyTarget;
  final VacationDaysInfo vacationInfo;
  final Duration overtimeHours;
  final TimesheetEntry? currentEntry;
  final ExtendedTimerState? extendedTimerState;
  final WorkTimeInfo? workTimeInfo;
  final bool isLoading;
  final bool showFAB;

  const PointageContentMinimal({
    super.key,
    required this.etatActuel,
    required this.dernierPointage,
    required this.selectedDate,
    required this.progression,
    required this.pointages,
    required this.onActionPointage,
    required this.onModifierPointage,
    required this.onSignalerAbsencePeriode,
    required this.onDeleteEntry,
    required this.totalDayHours,
    required this.monthlyHoursStatus,
    this.absenceReason,
    this.absence,
    required this.totalBreakTime,
    required this.weeklyWorkTime,
    required this.weeklyTarget,
    required this.vacationInfo,
    required this.overtimeHours,
    this.currentEntry,
    this.extendedTimerState,
    this.workTimeInfo,
    this.isLoading = false,
    this.showFAB = true,
  });

  @override
  Widget build(BuildContext context) {
    // Version ultra-minimale - juste le layout sans aucun wrapper
    return Stack(
      children: [
        PointageLayout(
          etatActuel: etatActuel,
          dernierPointage: dernierPointage,
          selectedDate: selectedDate,
          progression: progression,
          pointages: pointages,
          onActionPointage: onActionPointage,
          onModifierPointage: onModifierPointage,
          onSignalerAbsencePeriode: onSignalerAbsencePeriode,
          onDeleteEntry: onDeleteEntry,
          totalDayHours: totalDayHours,
          monthlyHoursStatus: monthlyHoursStatus,
          absenceReason: absenceReason,
          absence: absence,
          totalBreakTime: totalBreakTime,
          weeklyWorkTime: weeklyWorkTime,
          weeklyTarget: weeklyTarget,
          vacationInfo: vacationInfo,
          overtimeHours: overtimeHours,
          currentEntry: currentEntry,
          extendedTimerState: extendedTimerState,
          workTimeInfo: workTimeInfo,
        ),
        if (showFAB)
          Positioned(
            bottom: 16,
            right: 16,
            child: PointageFAB(
              etatActuel: etatActuel,
              onPressed: onActionPointage,
              isLoading: isLoading,
            ),
          ),
      ],
    );
  }
}
