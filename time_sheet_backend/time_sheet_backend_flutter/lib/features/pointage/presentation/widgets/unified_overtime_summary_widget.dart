import 'package:flutter/material.dart';
import '../../../../services/unified_overtime_calculator.dart';
import '../../../preference/presentation/widgets/overtime_calculation_mode_widget.dart';

/// Widget pour afficher le résumé des heures supplémentaires
/// selon le mode de calcul configuré
class UnifiedOvertimeSummaryWidget extends StatelessWidget {
  final UnifiedOvertimeSummary summary;
  final bool showModeIndicator;
  final bool showDetailedBreakdown;

  const UnifiedOvertimeSummaryWidget({
    super.key,
    required this.summary,
    this.showModeIndicator = true,
    this.showDetailedBreakdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildMainSummary(context),
            if (showDetailedBreakdown) ...[
              const SizedBox(height: 16),
              _buildDetailedBreakdown(context),
            ],
            if (summary.mode ==
                OvertimeCalculationMode.monthlyWithCompensation) ...[
              const SizedBox(height: 16),
              _buildCompensationInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          summary.mode.icon,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Résumé des heures supplémentaires',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (showModeIndicator) ...[
                const SizedBox(height: 4),
                Text(
                  summary.mode.displayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (summary.hasOvertime)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              summary.formattedTotalOvertime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainSummary(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryItem(
            context,
            'Heures régulières',
            summary.formattedRegularHours,
            Icons.access_time,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryItem(
            context,
            'Heures supplémentaires',
            summary.formattedTotalOvertime,
            Icons.trending_up,
            summary.hasOvertime ? Colors.orange : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedBreakdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Détail par type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildBreakdownItem(
                context,
                'Weekday',
                summary.formattedWeekdayOvertime,
                '${summary.weekdayOvertimeRate}x',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBreakdownItem(
                context,
                'Weekend',
                summary.formattedWeekendOvertime,
                '${summary.weekendOvertimeRate}x',
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildWorkingDaysInfo(context),
      ],
    );
  }

  Widget _buildBreakdownItem(
    BuildContext context,
    String type,
    String hours,
    String rate,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            hours,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            rate,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingDaysInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDayCount(
            context,
            'Jours travaillés',
            summary.workingDaysCount.toString(),
            Icons.work,
          ),
          _buildDayCount(
            context,
            'Weekends travaillés',
            summary.weekendDaysWorked.toString(),
            Icons.weekend,
          ),
        ],
      ),
    );
  }

  Widget _buildDayCount(
    BuildContext context,
    String label,
    String count,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(height: 2),
        Text(
          count,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildCompensationInfo(BuildContext context) {
    if (summary.deficitHours == Duration.zero) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            const SizedBox(width: 8),
            Text(
              'Aucun déficit d\'heures ce mois',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compensation des déficits',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),

        // Barre de progression de la compensation
        _buildCompensationProgressBar(context),

        const SizedBox(height: 8),

        // Détails de la compensation
        Row(
          children: [
            Expanded(
              child: _buildCompensationDetail(
                context,
                'Déficit total',
                summary.formattedDeficitHours,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompensationDetail(
                context,
                'Compensé',
                summary.formattedCompensatedDeficitHours,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompensationDetail(
                context,
                'Restant',
                summary.formattedUncompensatedDeficitHours,
                summary.hasUncompensatedDeficit ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompensationProgressBar(BuildContext context) {
    final percentage = summary.deficitCompensationPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Compensation',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage / 100.0,
          backgroundColor: Colors.red.shade100,
          valueColor: AlwaysStoppedAnimation<Color>(
            percentage >= 100 ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildCompensationDetail(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

// Widget de comparaison supprimé car il n'y a plus qu'un seul mode de calcul (mensuel)
