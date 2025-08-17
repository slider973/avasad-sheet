import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_entry.dart';
import 'package:time_sheet/features/pointage/domain/use_cases/toggle_overtime_hours_use_case.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/overtime_indicator.dart';
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
                      Text(
                        entry.dayOfWeekDate,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
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
                  isActive: entry.hasOvertimeHours,
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
                _buildTimeSection('Matin', entry.startMorning, entry.endMorning),
                const SizedBox(width: 24),
                _buildTimeSection('Après-midi', entry.startAfternoon, entry.endAfternoon),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: entry.hasOvertimeHours ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total: ${hours}h ${minutes.toString().padLeft(2, '0')}min',
                style: TextStyle(
                  color: entry.hasOvertimeHours ? Colors.orange[700] : Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            start.isEmpty && end.isEmpty ? '-' : '${start.isEmpty ? '-' : start} → ${end.isEmpty ? '-' : end}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
