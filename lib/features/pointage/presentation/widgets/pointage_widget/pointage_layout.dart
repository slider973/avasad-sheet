import 'package:flutter/material.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence_bouton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_boutton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_list.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_remove_timesheet_day.dart';

import '../../../domain/entities/timesheet_entry.dart';
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
  final Function(DateTime, DateTime, String, String) onSignalerAbsencePeriode;
  final VoidCallback onDeleteEntry;
  final Duration totalDayHours;
  final String monthlyHoursStatus;
  final String? absenceReason;

  const PointageLayout({
    Key? key,
    required this.etatActuel,
    required this.dernierPointage,
    required this.progression,
    required this.pointages,
    required this.onActionPointage,
    required this.onModifierPointage,
    required this.selectedDate,
    required this.onSignalerAbsencePeriode,
    required this.totalDayHours,
    required this.monthlyHoursStatus,
    this.absenceReason,
    required this.onDeleteEntry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (absenceReason != null && absenceReason!.isNotEmpty) {
      // Vue pour une journée d'absence
      return PointageAbsence(
        absenceReason: absenceReason,
        onDeleteEntry: onDeleteEntry,
        etatActuel: etatActuel,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PointageHeader(selectedDate: selectedDate),
          const SizedBox(height: 20),
          PointageTimer(
            etatActuel: etatActuel,
            dernierPointage: dernierPointage,
            progression: progression,
          ),
          const SizedBox(height: 20),
          Text(
            'Total du jour : ${_formatDuration(totalDayHours)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          PointageButton(
            etatActuel: etatActuel,
            onPressed: onActionPointage,
          ),
          const SizedBox(height: 20),
          PointageAbsenceBouton(
            etatActuel: etatActuel,
            onSignalerAbsencePeriode: onSignalerAbsencePeriode,
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
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }
}
