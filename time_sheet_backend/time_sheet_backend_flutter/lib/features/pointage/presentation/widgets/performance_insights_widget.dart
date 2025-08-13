import 'package:flutter/material.dart';

class PerformanceInsightsWidget extends StatelessWidget {
  final double totalHours;
  final double progress;

  const PerformanceInsightsWidget({
    Key? key,
    required this.totalHours,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analyse de Performance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInsightItem(
              icon: Icons.trending_up,
              title: 'Tendance',
              description: _getPerformanceTrend(progress),
              color: _getPerformanceColor(progress),
            ),
            const Divider(),
            _buildInsightItem(
              icon: Icons.access_time,
              title: 'Moyenne Journalière',
              description: 'Moyenne de ${_formatTime(totalHours / 21.0)} par jour',
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  String _getPerformanceTrend(double progress) {
    final double daysInMonth = DateTime.now().day.toDouble();
    final double expectedProgress = (daysInMonth / 21.0) * 100.0;

    if (progress >= expectedProgress + 5) {
      return 'En avance sur l\'objectif';
    } else if (progress <= expectedProgress - 5) {
      return 'Légèrement en retard sur l\'objectif';
    } else {
      return 'Dans les temps';
    }
  }
  String _formatTime(double hours) {
    final int wholeHours = hours.floor();
    final int minutes = ((hours - wholeHours) * 60.0).round();
    return '${wholeHours}h${minutes.toString().padLeft(2, '0')}';
  }

  Color _getPerformanceColor(double progress) {
    final double daysInMonth = DateTime.now().day.toDouble();
    final double expectedProgress = (daysInMonth / 21.0) * 100.0;

    if (progress >= expectedProgress + 5) {
      return Colors.green;
    } else if (progress <= expectedProgress - 5) {
      return Colors.orange;
    } else {
      return Colors.blue;
    }
  }
}
