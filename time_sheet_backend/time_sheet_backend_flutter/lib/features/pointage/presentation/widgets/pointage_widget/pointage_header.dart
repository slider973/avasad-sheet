import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/weekend_badge.dart';
import 'package:time_sheet/services/weekend_detection_service.dart';

class PointageHeader extends StatelessWidget {
  final DateTime selectedDate;

  const PointageHeader({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE d MMMM yyyy', 'fr_FR');
    final formattedDate = dateFormat.format(selectedDate);
    final isWeekend = WeekendDetectionService().isWeekend(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Heure de pointage',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            WeekendBadge(
              isWeekend: isWeekend,
              isOvertimeEnabled:
                  true, // Default to true, can be made configurable
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (isWeekend)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Heures supplémentaires automatiques',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
