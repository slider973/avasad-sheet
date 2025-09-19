import 'package:flutter/material.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_overtime_summary.dart';

/// Widget pour afficher le résumé des heures supplémentaires weekend
class WeekendOvertimeSummaryWidget extends StatelessWidget {
  final ValidationOvertimeSummary overtimeSummary;
  final bool showAlert;

  const WeekendOvertimeSummaryWidget({
    super.key,
    required this.overtimeSummary,
    this.showAlert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Résumé des heures supplémentaires',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (showAlert && overtimeSummary.hasWeekendOvertime) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                ],
              ],
            ),
            const Divider(height: 24),

            // Alerte pour heures weekend exceptionnelles
            if (showAlert && overtimeSummary.hasWeekendOvertime) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cet employé a travaillé ${overtimeSummary.weekendDaysWorked} jour(s) de weekend avec ${overtimeSummary.formattedWeekendOvertime} d\'heures supplémentaires.',
                        style: const TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Résumé des heures
            _buildHoursSummary(),

            if (overtimeSummary.hasOvertime) ...[
              const SizedBox(height: 16),
              _buildOvertimeBreakdown(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHoursSummary() {
    return Column(
      children: [
        _buildHoursRow(
          'Heures normales',
          overtimeSummary.formattedRegularHours,
          Colors.green,
          Icons.schedule,
        ),
        const SizedBox(height: 8),
        _buildHoursRow(
          'Heures supplémentaires totales',
          overtimeSummary.formattedTotalOvertime,
          Colors.blue,
          Icons.add_alarm,
        ),
        const SizedBox(height: 4),
        Container(
          height: 1,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        _buildHoursRow(
          'Total général',
          overtimeSummary.formattedTotalHours,
          Colors.black87,
          Icons.timer,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildOvertimeBreakdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détail des heures supplémentaires',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        // Heures supplémentaires de semaine
        if (overtimeSummary.hasWeekdayOvertime) ...[
          _buildOvertimeDetailRow(
            'Heures supplémentaires semaine',
            overtimeSummary.formattedWeekdayOvertime,
            '${overtimeSummary.weekdayOvertimeRate}x',
            '${overtimeSummary.weekdayOvertimeDays} jour(s)',
            Colors.indigo,
            Icons.business,
          ),
          const SizedBox(height: 8),
        ],

        // Heures supplémentaires de weekend
        if (overtimeSummary.hasWeekendOvertime) ...[
          _buildOvertimeDetailRow(
            'Heures supplémentaires weekend',
            overtimeSummary.formattedWeekendOvertime,
            '${overtimeSummary.weekendOvertimeRate}x',
            '${overtimeSummary.weekendDaysWorked} jour(s)',
            Colors.orange,
            Icons.weekend,
          ),
        ],
      ],
    );
  }

  Widget _buildHoursRow(
    String label,
    String value,
    Color color,
    IconData icon, {
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  Widget _buildOvertimeDetailRow(
    String label,
    String hours,
    String rate,
    String days,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  rate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                days,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                hours,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
