import 'package:flutter/material.dart';
import 'package:time_sheet/features/absence/domain/entities/absence_entity.dart';
import 'package:time_sheet/features/pointage/domain/entities/extended_timer_state.dart';
import 'package:time_sheet/features/pointage/domain/entities/work_time_info.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/absence/domain/value_objects/absence_type.dart';
import 'package:time_sheet/features/pointage/domain/value_objects/vacation_days_info.dart';

import 'pointage_layout.dart';
import 'pointage_fab.dart';

/// Écran principal de pointage avec FAB intégré
/// Combine le layout de pointage avec le Floating Action Button moderne
/// Peut être utilisé avec ou sans navigation selon le contexte
class PointageScreen extends StatelessWidget {
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
  final bool showAppBar; // Nouveau paramètre pour contrôler l'AppBar
  final Duration? dailyWorkThreshold; // Objectif journalier configurable

  const PointageScreen({
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
    this.showAppBar = true, // Par défaut, affiche l'AppBar
    this.dailyWorkThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final pointageContent = PointageLayout(
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
      dailyWorkThreshold: dailyWorkThreshold,
    );

    final fab = PointageFAB(
      etatActuel: etatActuel,
      onPressed: onActionPointage,
      isLoading: isLoading,
    );

    // Le contenu est simplement le pointageContent
    final bodyContent = pointageContent;

    // Si showAppBar est false, retourne juste le contenu avec FAB
    if (!showAppBar) {
      return Scaffold(
        backgroundColor: Colors.teal[50],
        body: SafeArea(
          bottom: false, // Exclut le padding bottom du SafeArea
          child: Stack(
            children: [
              bodyContent,
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom +
                    16, // Gère manuellement le padding bottom
                right: 16,
                child: fab,
              ),
            ],
          ),
        ),
      );
    }

    // Sinon, retourne avec AppBar complet
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Pointage'),
        elevation: 0,
      ),
      backgroundColor: Colors.teal[50],
      body: SafeArea(
        bottom: false, // Exclut le padding bottom du SafeArea
        child: Stack(
          children: [
            bodyContent,
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom +
                  16, // Gère manuellement le padding bottom
              right: 12,
              child: fab,
            ),
          ],
        ),
      ),
    );
  }
}

/// Version compacte de l'écran de pointage pour les petits écrans
class PointageScreenCompact extends StatelessWidget {
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

  const PointageScreenCompact({
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
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PointageLayout(
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
      floatingActionButton: PointageFABCompact(
        etatActuel: etatActuel,
        onPressed: onActionPointage,
        isLoading: isLoading,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// Widget de contenu pointage sans Scaffold - pour intégration dans d'autres écrans
/// Parfait pour utilisation dans TabView, BottomSheet, ou écrans avec navigation existante
class PointageContent extends StatelessWidget {
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
  final bool showFAB; // Contrôle l'affichage du FAB
  final bool removeTopPadding; // Nouveau: supprime le padding du haut

  const PointageContent({
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
    this.removeTopPadding = false, // Par défaut, garde le padding
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.teal[50],
          // Supprime le padding du haut si demandé (pour TabView)
          padding: removeTopPadding
              ? const EdgeInsets.only(bottom: 80) // Espace pour FAB
              : null,
          child: PointageLayout(
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
        ),
        if (showFAB)
          Positioned(
            bottom: 20,
            right: 12,
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

/// Extension pour déterminer automatiquement quelle version utiliser
extension PointageScreenBuilder on Widget {
  /// Construit automatiquement la version appropriée selon la taille d'écran
  static Widget adaptive({
    required BuildContext context,
    required String etatActuel,
    required DateTime? dernierPointage,
    required DateTime selectedDate,
    required double progression,
    required List<Map<String, dynamic>> pointages,
    required VoidCallback onActionPointage,
    required Function(Map<String, dynamic>) onModifierPointage,
    required Function(DateTime, DateTime, String, AbsenceType, String, String,
            TimeOfDay?, TimeOfDay?)
        onSignalerAbsencePeriode,
    required VoidCallback onDeleteEntry,
    required Duration totalDayHours,
    required String monthlyHoursStatus,
    String? absenceReason,
    AbsenceEntity? absence,
    required Duration totalBreakTime,
    required Duration weeklyWorkTime,
    required Duration weeklyTarget,
    required VacationDaysInfo vacationInfo,
    required Duration overtimeHours,
    TimesheetEntry? currentEntry,
    ExtendedTimerState? extendedTimerState,
    WorkTimeInfo? workTimeInfo,
    bool isLoading = false,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 400;

    if (isCompact) {
      return PointageScreenCompact(
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
        isLoading: isLoading,
      );
    }

    return PointageScreen(
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
      isLoading: isLoading,
    );
  }
}
