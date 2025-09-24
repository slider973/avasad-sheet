import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/weekend_badge.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_design_system.dart';
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

    return Container(
      padding: PointageSpacing.sectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with weekend badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Heure de pointage',
                  style: PointageTextStyles.pageTitle,
                ),
              ),
              WeekendBadge(
                isWeekend: isWeekend,
                isOvertimeEnabled:
                    true, // Default to true, can be made configurable
              ),
            ],
          ),
          SizedBox(height: PointageSpacing.sm),

          // Date row with overtime indicator
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _capitalizeFirstLetter(formattedDate),
                  style: PointageTextStyles.primaryTime.copyWith(
                    color: PointageColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (isWeekend) _buildOvertimeIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the overtime indicator for weekend days
  Widget _buildOvertimeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.sm,
        vertical: PointageSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: PointageColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PointageColors.warning.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: PointageColors.warning,
          ),
          const SizedBox(width: PointageSpacing.xs),
          Text(
            'Heures supplémentaires automatiques',
            style: PointageTextStyles.cardLabel.copyWith(
              fontSize: 12,
              color: PointageColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Capitalizes the first letter of a string
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
