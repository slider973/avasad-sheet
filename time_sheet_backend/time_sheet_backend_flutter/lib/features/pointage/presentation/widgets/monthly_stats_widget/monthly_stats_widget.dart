import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/timesheet_entry.dart';
import '../../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../daily_stats_widget.dart';
import '../monthly_overview_widget.dart';
import '../performance_insights_widget.dart';
import '../weekly_progress_widget.dart';

class MonthlyStatsWidget extends StatefulWidget {
  static const double MONTHLY_TARGET_HOURS = 168.0;

  const MonthlyStatsWidget({super.key});

  @override
  _MonthlyStatsWidgetState createState() => _MonthlyStatsWidgetState();
}

class _MonthlyStatsWidgetState extends State<MonthlyStatsWidget> {
  @override
  void initState() {
    super.initState();
    // Charger les données dès que le widget est monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<TimeSheetBloc>()
          .add(LoadMonthlyEntriesEvent(DateTime.now().month));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeSheetBloc, TimeSheetState>(
      builder: (context, state) {
        if (state is! TimeSheetDataState) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<TimesheetEntry> weeklyEntries =
            _filterCurrentWeekEntries(state.monthlyEntries);
        final double totalHours = _calculateMonthlyHours(state.monthlyEntries);
        final double remainingHours =
            (MonthlyStatsWidget.MONTHLY_TARGET_HOURS - totalHours).toDouble();
        final double progress =
            ((totalHours / MonthlyStatsWidget.MONTHLY_TARGET_HOURS) * 100.0)
                .clamp(0.0, 100.0);

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<TimeSheetBloc>()
                .add(LoadMonthlyEntriesEvent(DateTime.now().month));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Widget Aperçu Mensuel
                  MonthlyOverviewWidget(
                    totalHours: totalHours,
                    remainingHours: remainingHours,
                    progress: progress,
                    entries: state.monthlyEntries,
                  ),
                  const SizedBox(height: 24),

                  // Widget Progression Hebdomadaire
                  WeeklyProgressWidget(entries: weeklyEntries),
                  const SizedBox(height: 24),

                  // Widget Statistiques Journalières
                  DailyStatsWidget(entry: state.entry),
                  const SizedBox(height: 24),

                  // Widget Analyse de Performance
                  PerformanceInsightsWidget(
                    totalHours: totalHours,
                    progress: progress,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<TimesheetEntry> _filterCurrentWeekEntries(List<TimesheetEntry> entries) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(
        Duration(days: now.weekday - 1)); // Début de la semaine (lundi)
    final endOfWeek = startOfWeek
        .add(const Duration(days: 6)); // Fin de la semaine (dimanche)

    return entries.where((entry) {
      final entryDate = DateFormat("dd-MMM-yy").parse(entry.dayDate);
      return entryDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          entryDate.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  double _calculateMonthlyHours(List<TimesheetEntry> entries) {
    return entries.fold(0.0, (total, entry) {
      return total + entry.calculateDailyTotal().inMinutes.toDouble() / 60.0;
    });
  }
}
