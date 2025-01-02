import 'package:flutter/material.dart';

class MonthlyOverviewWidget extends StatelessWidget {
  final double totalHours;
  final double remainingHours;
  final double progress;

  const MonthlyOverviewWidget({
    Key? key,
    required this.totalHours,
    required this.remainingHours,
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
                _buildStat('Heures Travaillées', _formatTime(totalHours), Colors.blue),
                _buildStat('Heures Restantes', _formatTime(remainingHours), Colors.orange),
                _buildStat('Progression', '${progress.toStringAsFixed(1)}%', Colors.green),
              ],
            ),
          ],
        ),
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
}
