import 'package:flutter/material.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence_bouton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_boutton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_list.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_remove_timesheet_day.dart';
import 'package:time_sheet/features/pointage/use_cases/get_remaining_vacation_days_usecase.dart';

// import '../monthly_stats_widget/monthly_stats_widget.dart';
import '../vacation_days_detail_card/vacation_days_detail_card.dart';
import 'pointage_header.dart';
import 'pointage_timer.dart';

class PointageLayout extends StatelessWidget {
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

  const PointageLayout({
    Key? key,
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (absenceReason != null && absenceReason!.isNotEmpty) {
      return PointageAbsence(
        absenceReason: absenceReason!,
        absence: absence,
        onDeleteEntry: onDeleteEntry,
        etatActuel: etatActuel,
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PointageHeader(selectedDate: selectedDate),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total du jour : ${_formatDuration(totalDayHours)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Temps de pause : ${_formatDuration(totalBreakTime)}',
                        style: const TextStyle(
                            fontSize: 14, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                PointageTimer(
                  etatActuel: etatActuel,
                  dernierPointage: dernierPointage,
                  progression: progression,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildWeeklySummary(),
            const SizedBox(height: 20),
            _buildAdditionalInfo(),
            const SizedBox(height: 20),
            PointageButton(
              etatActuel: etatActuel,
              onPressed: onActionPointage,
            ),
            const SizedBox(height: 20),
            PointageAbsenceBouton(
              etatActuel: etatActuel,
              onSignalerAbsencePeriode: onSignalerAbsencePeriode,
              selectedDate: selectedDate,
            ),
            const SizedBox(height: 10),
            PointageRemoveTimesheetDay(
              etatActuel: etatActuel,
              onDeleteEntry: onDeleteEntry,
              isDisabled: etatActuel == 'Non commencé',
            ),
            const SizedBox(height: 20),
            PointageList(
              pointages: pointages,
              onModifier: onModifierPointage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Résumé hebdomadaire',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: weeklyTarget.inMinutes > 0
                  ? (weeklyWorkTime.inMinutes / weeklyTarget.inMinutes)
                      .clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            const SizedBox(height: 8),
            Text(
                '${_formatDuration(weeklyWorkTime)} / ${_formatDuration(weeklyTarget)}'),
          ],
        ),
      ),
    );
  }

// Dans pointage_layout.dart, modifions la méthode _buildAdditionalInfo

  Widget _buildAdditionalInfo() {
    return Column(
      children: [
        VacationDaysDetailCard(
          currentYearTotal: 25,
          lastYearRemaining: vacationInfo.lastYearRemaining,
          usedDays: vacationInfo.usedDays,
          remainingTotal: vacationInfo.remainingTotal,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }
  

}
