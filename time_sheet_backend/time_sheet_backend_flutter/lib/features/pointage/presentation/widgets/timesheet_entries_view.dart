import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/timesheet_entry.dart';
import '../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import 'timesheet_entry_card.dart';
import '../../../../services/weekend_overtime_calculator.dart';
import '../../../../services/injection_container.dart';

enum OvertimeFilter { all, weekdayOnly, weekendOnly }

class TimesheetEntriesWidget extends StatefulWidget {
  const TimesheetEntriesWidget({super.key});

  @override
  State<TimesheetEntriesWidget> createState() => _TimesheetEntriesWidgetState();
}

class _TimesheetEntriesWidgetState extends State<TimesheetEntriesWidget> {
  OvertimeFilter _currentFilter = OvertimeFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heures enregistrées'),
        actions: [
          PopupMenuButton<OvertimeFilter>(
            icon: const Icon(Icons.filter_list),
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: OvertimeFilter.all,
                child: Row(
                  children: [
                    Icon(Icons.list),
                    SizedBox(width: 8),
                    Text('Toutes les heures'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: OvertimeFilter.weekdayOnly,
                child: Row(
                  children: [
                    Icon(Icons.business_center),
                    SizedBox(width: 8),
                    Text('Heures semaine uniquement'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: OvertimeFilter.weekendOnly,
                child: Row(
                  children: [
                    Icon(Icons.weekend),
                    SizedBox(width: 8),
                    Text('Heures weekend uniquement'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context
                  .read<TimeSheetListBloc>()
                  .add(const FindTimesheetEntriesEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<TimeSheetListBloc, TimeSheetListState>(
        builder: (context, state) {
          if (state is TimeSheetListInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is TimeSheetListFetchedState) {
            final filteredEntries = _filterEntries(state.entries);

            if (filteredEntries.isEmpty) {
              return _buildEmptyState();
            }

            return Column(
              children: [
                _buildSummaryHeader(state.entries),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = filteredEntries[index];
                      return TimesheetEntryCard(
                        entry: entry,
                        onRefresh: () {
                          context
                              .read<TimeSheetListBloc>()
                              .add(const FindTimesheetEntriesEvent());
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: Text('Une erreur est survenue'));
          }
        },
      ),
    );
  }

  List<TimesheetEntry> _filterEntries(List<TimesheetEntry> entries) {
    switch (_currentFilter) {
      case OvertimeFilter.weekdayOnly:
        return entries
            .where((entry) => !entry.isWeekend && entry.hasOvertimeHours)
            .toList();
      case OvertimeFilter.weekendOnly:
        return entries.where((entry) => entry.isWeekend).toList();
      case OvertimeFilter.all:
        return entries;
    }
  }

  Widget _buildEmptyState() {
    String message;
    switch (_currentFilter) {
      case OvertimeFilter.weekdayOnly:
        message = 'Aucune heure supplémentaire de semaine trouvée';
        break;
      case OvertimeFilter.weekendOnly:
        message = 'Aucune heure de weekend trouvée';
        break;
      case OvertimeFilter.all:
        message = 'Aucune heure enregistrée';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(List<TimesheetEntry> allEntries) {
    return FutureBuilder<OvertimeSummary>(
      future: getIt<WeekendOvertimeCalculator>()
          .calculateMonthlyOvertime(allEntries),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final summary = snapshot.data!;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Résumé des heures supplémentaires',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryTile(
                      'Semaine',
                      summary.weekdayOvertime,
                      Colors.orange,
                      Icons.business_center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryTile(
                      'Weekend',
                      summary.weekendOvertime,
                      Colors.deepOrange,
                      Icons.weekend,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryTile(
                      'Total',
                      summary.totalOvertime,
                      Colors.blue,
                      Icons.schedule,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTile(
      String label, Duration duration, Color color, IconData icon) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            '${hours}h${minutes.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
