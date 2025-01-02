import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/timesheet_entry.dart';

class DailyStatsWidget extends StatelessWidget {
  static const double DAILY_TARGET_HOURS = 8.3;
  final TimesheetEntry entry;

   const DailyStatsWidget({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final double dailyHours = _calculateDailyHours(entry, today);
    final double dailyProgress =
        ((dailyHours / DAILY_TARGET_HOURS) * 100.0).clamp(0.0, 100.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques Journalières',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aujourd\'hui (${DateFormat('dd/MM').format(today)})',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(dailyHours),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'sur ${_formatTime(DAILY_TARGET_HOURS)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: dailyProgress / 100.0,
                        backgroundColor: Colors.grey[200],
                        strokeWidth: 8,
                      ),
                      Center(
                        child: Text(
                          '${dailyProgress.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _calculateDailyHours(TimesheetEntry entry, DateTime date) {
    if (date.weekday >= DateTime.monday && date.weekday <= DateTime.friday) {
      final duration = entry.calculateDailyTotal();
      return duration.inMinutes.toDouble() / 60.0;
    }
    return 0.0;
  }

  String _formatTime(double hours) {
    final int wholeHours = hours.floor();
    final int minutes = ((hours - wholeHours) * 60.0).round();
    return '${wholeHours}h${minutes.toString().padLeft(2, '0')}';
  }
}
