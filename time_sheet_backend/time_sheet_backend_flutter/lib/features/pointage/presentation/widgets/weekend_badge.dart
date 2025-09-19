import 'package:flutter/material.dart';

/// A badge widget that displays weekend indicator
class WeekendBadge extends StatelessWidget {
  final bool isWeekend;
  final bool isOvertimeEnabled;

  const WeekendBadge({
    super.key,
    required this.isWeekend,
    this.isOvertimeEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isWeekend) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOvertimeEnabled
            ? Colors.orange.withValues(alpha: 0.1)
            : Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOvertimeEnabled
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.weekend,
            size: 14,
            color: isOvertimeEnabled ? Colors.orange[700] : Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            'Weekend',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOvertimeEnabled ? Colors.orange[700] : Colors.blue[700],
            ),
          ),
          if (isOvertimeEnabled) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.schedule,
              size: 12,
              color: Colors.orange[700],
            ),
          ],
        ],
      ),
    );
  }
}
