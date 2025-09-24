import 'package:flutter/material.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence_bouton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_boutton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_list.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_remove_timesheet_day.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/estimated_end_time_card.dart';

// import '../monthly_stats_widget/monthly_stats_widget.dart';
import '../../../../absence/domain/value_objects/absence_type.dart';
import '../../../domain/value_objects/vacation_days_info.dart';
import '../vacation_days_detail_card/vacation_days_detail_card.dart';
import 'pointage_header.dart';
import 'pointage_main_section.dart';
import 'pointage_design_system.dart';
import 'daily_objective_card.dart';
import 'overtime_toggle_card.dart';
import 'weekly_summary_card.dart';
import 'pointage_fab.dart';

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
  final TimesheetEntry? currentEntry;
  final VoidCallback onToggleOvertime;
  final ExtendedTimerState? extendedTimerState;
  final WorkTimeInfo? workTimeInfo;

  const PointageLayout({
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
    required this.onToggleOvertime,
    this.extendedTimerState,
    this.workTimeInfo,
  });

  @override
  Widget build(BuildContext context) {
    // Gestion du cas d'absence (exigence 7.1 - préservation fonctionnalité)
    if (absenceReason != null && absenceReason!.isNotEmpty) {
      return PointageTheme(
        child: PointageAbsence(
          absenceReason: absenceReason!,
          absence: absence,
          onDeleteEntry: onDeleteEntry,
          etatActuel: etatActuel,
        ),
      );
    }

    return PointageTheme(
      child: Container(
        color: PointageColors.background, // Fond harmonisé (exigence 8.1)
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(), // Amélioration UX (exigence 6.4)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section avec espacement optimisé (exigences 1.1, 1.2, 8.1, 8.2)
              _buildHeaderSection(),

              // Main Section - Timer + Time Info avec hiérarchie visuelle (exigences 3.1, 3.2, 3.3, 6.1, 6.3)
              _buildMainSection(),

              // Message de félicitations pour l'état 'Sortie'
              if (etatActuel == 'Sortie') ...[
                const SizedBox(height: PointageSpacing.lg),
                const PointageCompletionMessage(),
              ],

              // Info Cards Section avec espacement cohérent (exigences 4.1, 4.2, 4.3, 4.4, 7.5)
              _buildInfoCardsSection(),

              // Action Buttons Section - boutons secondaires (exigences 5.2, 5.4, 7.6)
              _buildActionButtonsSection(),

              // History Section avec séparation visuelle (exigences 4.5, 7.5, 7.7)
              _buildHistorySection(),

              // Espacement final pour éviter le collage au bas de l'écran
              const SizedBox(height: PointageSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  /// Section d'en-tête avec titre et date (exigences 1.1, 1.2, 8.1, 8.2)
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(PointageSpacing.md, PointageSpacing.sm,
          PointageSpacing.md, PointageSpacing.sm),
      child: PointageHeader(selectedDate: selectedDate),
    );
  }

  /// Section principale avec chronomètre et informations de temps (exigences 3.1, 3.2, 3.3, 6.1, 6.3)
  Widget _buildMainSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: PointageSpacing.md),
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: BoxDecoration(
        color: PointageColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PointageMainSection(
        etatActuel: etatActuel,
        dernierPointage: dernierPointage,
        progression: progression,
        pointages: pointages,
        totalDayHours: totalDayHours,
        totalBreakTime: totalBreakTime,
        extendedTimerState: extendedTimerState,
        workTimeInfo: workTimeInfo,
      ),
    );
  }

  /// Section des cartes d'information (exigences 4.1, 4.2, 4.3, 4.4, 7.5)
  Widget _buildInfoCardsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PointageSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: PointageSpacing.lg),

          // Heure de fin estimée (exigence 4.1, 7.5)
          EstimatedEndTimeCard(
            pointages: pointages,
            currentState: etatActuel,
          ),
          const SizedBox(height: PointageSpacing.md),

          // Objectif journalier (exigence 4.2)
          DailyObjectiveCard(
            pointages: pointages,
            currentState: etatActuel,
            currentWorkTime: totalDayHours,
          ),
          const SizedBox(height: PointageSpacing.md),

          // Toggle heures supplémentaires (exigence 4.3, 7.4)
          if (currentEntry != null && etatActuel != 'Non commencé') ...[
            OvertimeToggleCard(
              isActive: currentEntry!.hasOvertimeHours,
              onToggle: onToggleOvertime,
              description: 'Activer pour cette journée',
              isEnabled: true,
            ),
            const SizedBox(height: PointageSpacing.md),
          ],

          // Résumé hebdomadaire (exigence 4.4, 7.5)
          WeeklySummaryCard(
            weeklyWorkTime: weeklyWorkTime,
            weeklyTarget: weeklyTarget,
            overtimeHours: overtimeHours,
          ),
          const SizedBox(height: PointageSpacing.md),

          // Informations supplémentaires (congés, etc.)
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  /// Section des boutons d'action secondaires (exigences 5.2, 5.4, 7.6)
  Widget _buildActionButtonsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: PointageSpacing.md),
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: BoxDecoration(
        color: PointageColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre de section pour améliorer la hiérarchie visuelle (exigence 6.2)
          Text(
            'Actions supplémentaires',
            style: PointageTextStyles.cardLabel.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PointageColors.primary,
            ),
          ),
          const SizedBox(height: PointageSpacing.md),

          // Bouton d'absence (exigence 5.2, 7.6)
          PointageAbsenceBouton(
            etatActuel: etatActuel,
            onSignalerAbsencePeriode: onSignalerAbsencePeriode,
            selectedDate: selectedDate,
          ),
          const SizedBox(height: PointageSpacing.sm),

          // Bouton de suppression (exigence 5.4, 7.6)
          PointageRemoveTimesheetDay(
            etatActuel: etatActuel,
            onDeleteEntry: onDeleteEntry,
            isDisabled: etatActuel == 'Non commencé',
          ),
        ],
      ),
    );
  }

  /// Section de l'historique des pointages (exigences 4.5, 7.5, 7.7)
  Widget _buildHistorySection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          PointageSpacing.md, PointageSpacing.lg, PointageSpacing.md, 0),
      decoration: BoxDecoration(
        color: PointageColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de section avec séparation visuelle (exigence 6.2)
          Padding(
            padding: const EdgeInsets.fromLTRB(PointageSpacing.lg,
                PointageSpacing.lg, PointageSpacing.lg, PointageSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: PointageColors.primary,
                  size: 20,
                ),
                const SizedBox(width: PointageSpacing.sm),
                Text(
                  'Historique des pointages',
                  style: PointageTextStyles.cardLabel.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: PointageColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Ligne de séparation subtile
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: PointageSpacing.lg),
            color: PointageColors.divider,
          ),

          // Liste des pointages avec préservation complète des fonctionnalités (exigence 7.7)
          PointageList(
            pointages: pointages,
            onModifier: onModifierPointage,
          ),
        ],
      ),
    );
  }

  /// Informations supplémentaires (congés, etc.)
  Widget _buildAdditionalInfo() {
    return VacationDaysDetailCard(
      currentYearTotal: 25,
      lastYearRemaining: vacationInfo.lastYearRemaining,
      usedDays: vacationInfo.usedDays,
      remainingTotal: vacationInfo.remainingTotal,
    );
  }
}
