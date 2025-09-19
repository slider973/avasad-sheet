import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget to display the estimated end time of the work day
///
/// This widget shows when the employee is expected to finish their work day
/// based on the current progress and remaining work time. It updates in real-time
/// and provides visual feedback about the work schedule.
class EndTimeDisplay extends StatelessWidget {
  final DateTime? estimatedEndTime;
  final bool isOvertimeStarted;
  final String currentState;

  const EndTimeDisplay({
    super.key,
    required this.estimatedEndTime,
    required this.isOvertimeStarted,
    required this.currentState,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show end time if work hasn't started or is finished
    if (currentState == 'Non commencé' || currentState == 'Sortie') {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Fin prévue',
          style: TextStyle(
            fontSize: 12,
            color: isOvertimeStarted
                ? Colors.orange.shade700
                : const Color(0xFF7F8C8D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          estimatedEndTime != null
              ? DateFormat('HH:mm').format(estimatedEndTime!)
              : '--:--',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isOvertimeStarted
                ? Colors.orange.shade700
                : const Color(0xFF2D3E50),
          ),
        ),
      ],
    );
  }
}
