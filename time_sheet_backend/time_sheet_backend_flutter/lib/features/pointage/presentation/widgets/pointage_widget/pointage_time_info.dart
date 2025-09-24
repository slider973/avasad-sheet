import 'package:flutter/material.dart';
import 'pointage_design_system.dart';

/// Widget pour afficher les informations de temps à gauche du chronomètre
/// Affiche "Total du jour" et "Temps de pause" selon les exigences 3.1 et 3.2
class PointageTimeInfo extends StatelessWidget {
  final Duration totalDayHours;
  final Duration totalBreakTime;
  final VoidCallback? onTotalDayTap;
  final VoidCallback? onBreakTimeTap;

  const PointageTimeInfo({
    super.key,
    required this.totalDayHours,
    required this.totalBreakTime,
    this.onTotalDayTap,
    this.onBreakTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeInfoItem(
          context: context,
          label: 'Total du jour',
          value: _formatDuration(totalDayHours),
          style: PointageTextStyles.primaryTime,
          labelStyle: PointageTextStyles.cardLabel,
          onTap: onTotalDayTap,
          icon: Icons.work_outline,
          iconColor: PointageColors.entreeColor,
        ),
        const SizedBox(height: PointageSpacing.md),
        _buildTimeInfoItem(
          context: context,
          label: 'Temps de pause',
          value: _formatDuration(totalBreakTime),
          style: PointageTextStyles.secondaryTime,
          labelStyle: PointageTextStyles.cardLabel,
          onTap: onBreakTimeTap,
          icon: Icons.pause_circle_outline,
          iconColor: PointageColors.pauseColor,
        ),
      ],
    );
  }

  Widget _buildTimeInfoItem({
    required BuildContext context,
    required String label,
    required String value,
    required TextStyle style,
    required TextStyle labelStyle,
    VoidCallback? onTap,
    IconData? icon,
    Color? iconColor,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: iconColor ?? PointageColors.textSecondary,
              ),
              const SizedBox(width: PointageSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: labelStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: PointageSpacing.xs),
        Text(
          value,
          style: style,
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(PointageSpacing.sm),
          child: content,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(PointageSpacing.sm),
      child: content,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }
}

/// Variante compacte pour les petits écrans
class CompactPointageTimeInfo extends StatelessWidget {
  final Duration totalDayHours;
  final Duration totalBreakTime;

  const CompactPointageTimeInfo({
    super.key,
    required this.totalDayHours,
    required this.totalBreakTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactTimeItem(
          label: 'Total',
          value: _formatDuration(totalDayHours),
          icon: Icons.work_outline,
          iconColor: PointageColors.entreeColor,
        ),
        Container(
          width: 1,
          height: 24,
          color: PointageColors.divider,
        ),
        _buildCompactTimeItem(
          label: 'Pause',
          value: _formatDuration(totalBreakTime),
          icon: Icons.pause_circle_outline,
          iconColor: PointageColors.pauseColor,
        ),
      ],
    );
  }

  Widget _buildCompactTimeItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor,
        ),
        const SizedBox(height: PointageSpacing.xs),
        Text(
          label,
          style: PointageTextStyles.cardLabel.copyWith(fontSize: 12),
        ),
        Text(
          value,
          style: PointageTextStyles.cardValue.copyWith(fontSize: 14),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes";
  }
}
