import 'package:flutter/material.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../../../services/weekend_overtime_calculator.dart';
import '../../../../services/injection_container.dart';

class MonthlyOverviewWidget extends StatelessWidget {
  final double totalHours;
  final double remainingHours;
  final double progress;
  final List<TimesheetEntry>? entries;

  const MonthlyOverviewWidget({
    super.key,
    required this.totalHours,
    required this.remainingHours,
    required this.progress,
    this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aperçu Mensuel',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress / 100.0,
              backgroundColor: Colors.grey[200],
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                    'Heures Travaillées', _formatTime(totalHours), Colors.blue),
                _buildStat('Heures Restantes', _formatTime(remainingHours),
                    Colors.orange),
                _buildStat('Progression', '${progress.toStringAsFixed(1)}%',
                    Colors.green),
              ],
            ),
            if (entries != null) ...[
              const SizedBox(height: 20),
              _buildOvertimeBreakdown(entries!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOvertimeBreakdown(List<TimesheetEntry> entries) {
    return FutureBuilder<OvertimeSummary>(
      future:
          getIt<WeekendOvertimeCalculator>().calculateMonthlyOvertime(entries),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final summary = snapshot.data!;

        if (summary.totalOvertime.inMinutes == 0) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Aucune heure supplémentaire ce mois',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Heures Supplémentaires',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Overtime breakdown
            Row(
              children: [
                Expanded(
                  child: _buildOvertimeCard(
                    'Semaine',
                    summary.weekdayOvertime,
                    Colors.orange,
                    Icons.business_center,
                    'Taux: ${(summary.weekdayOvertimeRate * 100).toStringAsFixed(0)}%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildOvertimeCard(
                    'Weekend',
                    summary.weekendOvertime,
                    Colors.deepOrange,
                    Icons.weekend,
                    'Taux: ${(summary.weekendOvertimeRate * 100).toStringAsFixed(0)}%',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Total overtime with visual indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade50,
                    Colors.blue.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Heures Supplémentaires',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _formatDuration(summary.totalOvertime),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildOvertimeChart(summary),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOvertimeCard(String label, Duration duration, Color color,
      IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            _formatDuration(duration),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeChart(OvertimeSummary summary) {
    final totalMinutes = summary.totalOvertime.inMinutes;
    if (totalMinutes == 0) return const SizedBox.shrink();

    final weekdayRatio = summary.weekdayOvertime.inMinutes / totalMinutes;
    final weekendRatio = summary.weekendOvertime.inMinutes / totalMinutes;

    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          // Background circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
            ),
          ),
          // Weekend portion
          if (weekendRatio > 0)
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: weekendRatio,
                strokeWidth: 6,
                backgroundColor: Colors.transparent,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
              ),
            ),
          // Weekday portion
          if (weekdayRatio > 0)
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: weekdayRatio,
                strokeWidth: 6,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          // Center text
          Center(
            child: Text(
              '${totalMinutes ~/ 60}h',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _formatTime(double hours) {
    final int wholeHours = hours.floor();
    final int minutes = ((hours - wholeHours) * 60.0).round();
    return '${wholeHours}h${minutes.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }
}
