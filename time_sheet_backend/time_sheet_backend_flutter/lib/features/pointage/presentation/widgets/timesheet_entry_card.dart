import 'package:flutter/material.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/toggle_overtime_hours_use_case.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/overtime_indicator.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/weekend_badge.dart';
import 'package:time_sheet/services/injection_container.dart';

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
                OvertimeIndicator(
                  isActive: entry.hasOvertimeHours ||
                      (entry.isWeekend && entry.isWeekendOvertimeEnabled),
                  onToggle: () async {
                    final toggleUseCase = getIt<ToggleOvertimeHoursUseCase>();
                    await toggleUseCase.execute(
                      entryId: entry.id!,
                      hasOvertimeHours: !entry.hasOvertimeHours,
                    );
                    onRefresh();
                  },
                ),
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
                if (entry.hasOvertimeHours ||
                    (entry.isWeekend && entry.isWeekendOvertimeEnabled)) ...[
                  const SizedBox(width: 8),
                  _buildOvertimeTypeIndicator(entry),
                ],
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
    if (entry.isWeekend && entry.isWeekendOvertimeEnabled) {
      return Colors.deepOrange.withValues(alpha: 0.1);
    } else if (entry.hasOvertimeHours) {
      return Colors.orange.withValues(alpha: 0.1);
    } else {
      return Colors.blue.withValues(alpha: 0.1);
    }
  }

  Color? _getTotalTextColor(TimesheetEntry entry) {
    if (entry.isWeekend && entry.isWeekendOvertimeEnabled) {
      return Colors.deepOrange[700];
    } else if (entry.hasOvertimeHours) {
      return Colors.orange[700];
    } else {
      return Colors.blue[700];
    }
  }

  Widget _buildOvertimeTypeIndicator(TimesheetEntry entry) {
    String label;
    Color color;
    IconData icon;

    if (entry.isWeekend &&
        entry.isWeekendOvertimeEnabled &&
        entry.hasOvertimeHours) {
      // Both weekend and weekday overtime
      label = 'Mixte';
      color = Colors.purple;
      icon = Icons.all_inclusive;
    } else if (entry.isWeekend && entry.isWeekendOvertimeEnabled) {
      // Weekend overtime only
      label = 'Weekend';
      color = Colors.deepOrange;
      icon = Icons.weekend;
    } else if (entry.hasOvertimeHours) {
      // Weekday overtime only
      label = 'Semaine';
      color = Colors.orange;
      icon = Icons.business_center;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
