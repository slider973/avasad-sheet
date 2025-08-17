// /presentation/widgets/vacation_days_detail_card.dart

import 'package:flutter/material.dart';

class VacationDaysDetailCard extends StatelessWidget {
  final int currentYearTotal;
  final int lastYearRemaining;
  final int usedDays;
  final int remainingTotal;

  const VacationDaysDetailCard({
    super.key,
    required this.currentYearTotal,
    required this.lastYearRemaining,
    required this.usedDays,
    required this.remainingTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détail des congés',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Congés ${DateTime.now().year}', currentYearTotal),
            if (lastYearRemaining > 0) _buildDetailRow('Report ${DateTime.now().year - 1}', lastYearRemaining),
            const Divider(height: 24),
            _buildDetailRow('Total disponible', currentYearTotal + lastYearRemaining, isTotal: true),
            _buildDetailRow('Utilisés', usedDays),
            const Divider(height: 24),
            _buildDetailRow('Restants', remainingTotal, isHighlighted: true),
            const SizedBox(height: 8),
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, int value, {bool isTotal = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal || isHighlighted ? 16 : 14,
              fontWeight: isTotal || isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$value jours',
            style: TextStyle(
              fontSize: isTotal || isHighlighted ? 16 : 14,
              fontWeight: isTotal || isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? Colors.teal : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final total = currentYearTotal + lastYearRemaining;
    final progress = (remainingTotal / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toStringAsFixed(1)}% restants',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
