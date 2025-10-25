import 'package:flutter/material.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/weekend_badge.dart';

class TimesheetEntryCard extends StatelessWidget {
  final TimesheetEntry entry;
  final VoidCallback onRefresh;

  const TimesheetEntryCard({
    super.key,
    required this.entry,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final duration = entry.calculateDailyTotal();
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.dayOfWeekDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          WeekendBadge(
                            isWeekend: entry.isWeekend,
                            isOvertimeEnabled: entry.isWeekendOvertimeEnabled,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.dayDate,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                // L'indicateur HS n'est plus affiché car le calcul est mensuel
                // Seul le badge weekend reste visible
                const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTimeSection(
                    'Matin', entry.startMorning, entry.endMorning),
                const SizedBox(width: 24),
                _buildTimeSection(
                    'Après-midi', entry.startAfternoon, entry.endAfternoon),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getTotalBackgroundColor(entry),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Total: ${hours}h ${minutes.toString().padLeft(2, '0')}min',
                      style: TextStyle(
                        color: _getTotalTextColor(entry),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Plus d'indicateur de type d'heures sup car calcul mensuel
                // Le badge weekend suffit
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection(String label, String start, String end) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            start.isEmpty && end.isEmpty
                ? '-'
                : '${start.isEmpty ? '-' : start} → ${end.isEmpty ? '-' : end}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTotalBackgroundColor(TimesheetEntry entry) {
    // Seul le weekend a une couleur spéciale (orange)
    // Les jours de semaine sont en bleu (pas d'indication journalière)
    if (entry.isWeekend && entry.isWeekendOvertimeEnabled) {
      return Colors.deepOrange.withValues(alpha: 0.1);
    } else {
      return Colors.blue.withValues(alpha: 0.1);
    }
  }

  Color? _getTotalTextColor(TimesheetEntry entry) {
    // Seul le weekend a une couleur spéciale (orange)
    if (entry.isWeekend && entry.isWeekendOvertimeEnabled) {
      return Colors.deepOrange[700];
    } else {
      return Colors.blue[700];
    }
  }
}
