import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import '../../pages/pdf/bloc/anomaly/anomaly_bloc.dart';
import '../../pages/anomaly/anomaly.dart';
import '../../../../../services/weekend_overtime_calculator.dart';
import '../../../../../services/injection_container.dart';

class MetricsOverviewCard extends StatelessWidget {
  const MetricsOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, color: Colors.teal, size: 24),
                SizedBox(width: 8),
                Text(
                  'Vue d\'ensemble',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            BlocBuilder<TimeSheetListBloc, TimeSheetListState>(
              builder: (context, state) {
                if (state is TimeSheetListFetchedState) {
                  // Calculer les métriques à partir des données
                  final entries = state.entries;
                  final today = DateTime.now();

                  // Filtrer les entrées d'aujourd'hui
                  final todayEntries = entries.where((entry) {
                    return entry.date != null &&
                        entry.date!.year == today.year &&
                        entry.date!.month == today.month &&
                        entry.date!.day == today.day;
                  }).toList();

                  // Calculer les heures d'aujourd'hui
                  final todayHours = todayEntries.isNotEmpty
                      ? todayEntries.first.calculateDailyTotal()
                      : Duration.zero;

                  // Filtrer les entrées de cette semaine
                  final weekStart =
                      today.subtract(Duration(days: today.weekday - 1));
                  final weekEnd = weekStart.add(const Duration(days: 6));

                  final weekEntries = entries.where((entry) {
                    return entry.date != null &&
                        entry.date!.isAfter(
                            weekStart.subtract(const Duration(days: 1))) &&
                        entry.date!
                            .isBefore(weekEnd.add(const Duration(days: 1)));
                  }).toList();

                  // Calculer les heures de la semaine
                  final weekHours = weekEntries.fold<Duration>(
                    Duration.zero,
                    (total, entry) => total + entry.calculateDailyTotal(),
                  );

                  // Filtrer les entrées du mois
                  final monthEntries = entries.where((entry) {
                    return entry.date != null &&
                        entry.date!.year == today.year &&
                        entry.date!.month == today.month;
                  }).toList();

                  // Calculer les heures du mois
                  final monthHours = monthEntries.fold<Duration>(
                    Duration.zero,
                    (total, entry) => total + entry.calculateDailyTotal(),
                  );

                  // Calculer les heures supplémentaires sera fait dans le FutureBuilder

                  return Column(
                    children: [
                      Row(
                        children: [
                          // Aujourd'hui
                          Expanded(
                            child: _buildMetricTile(
                              'Aujourd\'hui',
                              _formatDuration(todayHours),
                              Icons.today,
                              Colors.blue,
                            ),
                          ),

                          // Cette semaine
                          Expanded(
                            child: _buildMetricTile(
                              'Cette semaine',
                              _formatDuration(weekHours),
                              Icons.date_range,
                              Colors.green,
                            ),
                          ),

                          // Ce mois
                          Expanded(
                            child: _buildMetricTile(
                              'Ce mois',
                              _formatDuration(monthHours),
                              Icons.calendar_month,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      // Overtime breakdown
                      FutureBuilder<OvertimeSummary>(
                        future: getIt<WeekendOvertimeCalculator>()
                            .calculateMonthlyOvertime(entries),
                        builder: (context, snapshot) {
                          if (snapshot.hasData &&
                              snapshot.data!.totalOvertime.inMinutes > 0) {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                _buildOvertimeBreakdown(snapshot.data!),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  );
                }

                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),

            const SizedBox(height: 16),

            // Alertes et anomalies
            BlocBuilder<AnomalyBloc, AnomalyState>(
              builder: (context, state) {
                if (state is AnomalyLoaded) {
                  final unresolvedCount = state.anomalies
                      .where((anomaly) => !anomaly.isResolved)
                      .length;

                  if (unresolvedCount > 0) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$unresolvedCount anomalie(s) à traiter',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigation vers la page des anomalies
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AnomalyView()),
                              );
                            },
                            child: const Text('Voir'),
                          ),
                        ],
                      ),
                    );
                  }
                }

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Aucune anomalie détectée',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
      String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeBreakdown(OvertimeSummary summary) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.teal.shade700, size: 16),
              const SizedBox(width: 6),
              Text(
                'Heures Supplémentaires du Mois',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildOvertimeMetric(
                  'Semaine',
                  summary.weekdayOvertime,
                  Colors.orange,
                  Icons.business_center,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOvertimeMetric(
                  'Weekend',
                  summary.weekendOvertime,
                  Colors.deepOrange,
                  Icons.weekend,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildOvertimeMetric(
                  'Total',
                  summary.totalOvertime,
                  Colors.teal,
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeMetric(
      String label, Duration duration, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _formatDuration(duration),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}min';
    } else {
      return '${minutes}min';
    }
  }
}
