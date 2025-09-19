import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import '../../../../../services/weekend_overtime_calculator.dart';
import '../../../../../services/injection_container.dart';
import '../../../domain/entities/timesheet_entry.dart';

class MonthlySummaryCard extends StatelessWidget {
  const MonthlySummaryCard({super.key});

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
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résumé mensuel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    BlocBuilder<TimeSheetListBloc, TimeSheetListState>(
                      builder: (context, state) {
                        final now = DateTime.now();
                        final startDay = now.day >= 21 ? 21 : 21;
                        final startMonth = now.day >= 21
                            ? now.month
                            : (now.month == 1 ? 12 : now.month - 1);
                        final endDay = 20;
                        final endMonth = now.day >= 21
                            ? (now.month == 12 ? 1 : now.month + 1)
                            : now.month;

                        final monthNames = [
                          '',
                          'Jan',
                          'Fév',
                          'Mar',
                          'Avr',
                          'Mai',
                          'Juin',
                          'Juil',
                          'Août',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Déc'
                        ];

                        return Text(
                          'Du $startDay ${monthNames[startMonth]} au $endDay ${monthNames[endMonth]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            BlocBuilder<TimeSheetListBloc, TimeSheetListState>(
              builder: (context, state) {
                if (state is TimeSheetListFetchedState) {
                  final entries = state.entries;
                  final now = DateTime.now();

                  // Déterminer la période actuelle (21 du mois précédent au 20 du mois courant)
                  DateTime startDate;
                  DateTime endDate;

                  if (now.day >= 21) {
                    // Du 21 du mois courant au 20 du mois suivant
                    startDate = DateTime(now.year, now.month, 21);
                    if (now.month == 12) {
                      endDate = DateTime(now.year + 1, 1, 20);
                    } else {
                      endDate = DateTime(now.year, now.month + 1, 20);
                    }
                  } else {
                    // Du 21 du mois précédent au 20 du mois courant
                    if (now.month == 1) {
                      startDate = DateTime(now.year - 1, 12, 21);
                    } else {
                      startDate = DateTime(now.year, now.month - 1, 21);
                    }
                    endDate = DateTime(now.year, now.month, 20);
                  }

                  // Filtrer les entrées de la période
                  final monthEntries = entries.where((entry) {
                    if (entry.date == null) return false;
                    final entryDate = entry.date!;
                    return !entryDate.isBefore(startDate) &&
                        !entryDate.isAfter(endDate);
                  }).toList();

                  // Calculer les statistiques mensuelles
                  final totalHours = monthEntries.fold<Duration>(
                    Duration.zero,
                    (total, entry) => total + entry.calculateDailyTotal(),
                  );

                  final workingDays = monthEntries.length;

                  // Calculer le nombre de jours ouvrables dans la période
                  int workingDaysInPeriod = 0;
                  for (DateTime date = startDate;
                      date.isBefore(endDate.add(Duration(days: 1)));
                      date = date.add(Duration(days: 1))) {
                    if (date.weekday >= DateTime.monday &&
                        date.weekday <= DateTime.friday) {
                      workingDaysInPeriod++;
                    }
                  }

                  final targetHours = Duration(hours: workingDaysInPeriod * 8);
                  final averagePerDay = workingDays > 0
                      ? Duration(minutes: totalHours.inMinutes ~/ workingDays)
                      : Duration.zero;

                  final progress = targetHours.inMinutes > 0
                      ? (totalHours.inMinutes / targetHours.inMinutes)
                          .clamp(0.0, 1.0)
                      : 0.0;

                  return Column(
                    children: [
                      // Total mensuel
                      _buildStatRow(
                        'Total du mois',
                        _formatDuration(totalHours),
                        Icons.access_time,
                        Colors.blue,
                      ),

                      const SizedBox(height: 12),

                      // Moyenne par jour
                      _buildStatRow(
                        'Moyenne/jour',
                        _formatDuration(averagePerDay),
                        Icons.trending_up,
                        Colors.green,
                      ),

                      const SizedBox(height: 12),

                      // Jours travaillés
                      _buildStatRow(
                        'Jours travaillés',
                        '$workingDays jours',
                        Icons.event_available,
                        Colors.orange,
                      ),

                      // Heures supplémentaires breakdown
                      _buildOvertimeSection(monthEntries),

                      const SizedBox(height: 16),

                      // Progression vers l'objectif
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Objectif mensuel',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                progress >= 1.0 ? Colors.green : Colors.teal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatDuration(totalHours)} / ${_formatDuration(targetHours)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Chargement des données...'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOvertimeSection(List<dynamic> monthEntries) {
    return FutureBuilder<OvertimeSummary>(
      future: getIt<WeekendOvertimeCalculator>()
          .calculateMonthlyOvertime(monthEntries.cast<TimesheetEntry>()),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.totalOvertime.inMinutes == 0) {
          return const SizedBox.shrink();
        }

        final overtimeSummary = snapshot.data!;

        return Column(
          children: [
            const SizedBox(height: 16),
            Container(
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
                      Icon(Icons.schedule,
                          color: Colors.teal.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Heures Supplémentaires',
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
                          overtimeSummary.weekdayOvertime,
                          Colors.orange,
                          '${(overtimeSummary.weekdayOvertimeRate * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOvertimeMetric(
                          'Weekend',
                          overtimeSummary.weekendOvertime,
                          Colors.deepOrange,
                          '${(overtimeSummary.weekendOvertimeRate * 100).toStringAsFixed(0)}%',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOvertimeMetric(
                          'Total',
                          overtimeSummary.totalOvertime,
                          Colors.teal,
                          '',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOvertimeMetric(
      String label, Duration duration, Color color, String rate) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDuration(duration),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
          if (rate.isNotEmpty)
            Text(
              rate,
              style: TextStyle(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
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
