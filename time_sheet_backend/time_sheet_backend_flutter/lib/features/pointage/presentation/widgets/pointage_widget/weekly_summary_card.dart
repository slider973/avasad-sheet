import 'package:flutter/material.dart';
import 'modern_info_card.dart';
import 'pointage_design_system.dart';

/// Card modernisée pour le résumé hebdomadaire avec barre de progression
class WeeklySummaryCard extends StatelessWidget {
  final Duration weeklyWorkTime;
  final Duration weeklyTarget;
  final Duration? overtimeHours;
  final String? subtitle;

  const WeeklySummaryCard({
    super.key,
    required this.weeklyWorkTime,
    required this.weeklyTarget,
    this.overtimeHours,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = _calculateProgressValue();
    final isTargetReached = weeklyWorkTime >= weeklyTarget;
    final remainingTime =
        isTargetReached ? Duration.zero : weeklyTarget - weeklyWorkTime;

    return ModernInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_view_week,
                color: isTargetReached
                    ? PointageColors.success
                    : PointageColors.primary,
                size: 24,
              ),
              const SizedBox(width: PointageSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé hebdomadaire',
                      style: PointageTextStyles.cardLabel.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: PointageTextStyles.cardLabel.copyWith(
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.md),

          // Temps travaillé vs objectif
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(weeklyWorkTime),
                style: PointageTextStyles.cardValue.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isTargetReached
                      ? PointageColors.success
                      : PointageColors.primary,
                ),
              ),
              Text(
                '/ ${_formatDuration(weeklyTarget)}',
                style: PointageTextStyles.cardLabel,
              ),
            ],
          ),

          const SizedBox(height: PointageSpacing.sm),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: PointageColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isTargetReached
                    ? PointageColors.success
                    : PointageColors.primary,
              ),
              minHeight: 8,
            ),
          ),

          const SizedBox(height: PointageSpacing.sm),

          // Informations supplémentaires
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!isTargetReached)
                Text(
                  'Il reste ${_formatDuration(remainingTime)}',
                  style: PointageTextStyles.cardLabel.copyWith(
                    fontSize: 12,
                  ),
                )
              else
                Text(
                  'Objectif atteint',
                  style: PointageTextStyles.cardLabel.copyWith(
                    fontSize: 12,
                    color: PointageColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              Text(
                '${(progressValue * 100).toInt()}%',
                style: PointageTextStyles.cardLabel.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isTargetReached
                      ? PointageColors.success
                      : PointageColors.primary,
                ),
              ),
            ],
          ),

          // Heures supplémentaires si présentes
          if (overtimeHours != null && overtimeHours! > Duration.zero)
            Container(
              margin: const EdgeInsets.only(top: PointageSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: PointageSpacing.sm,
                vertical: PointageSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: PointageColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time_filled,
                    size: 16,
                    color: PointageColors.warning,
                  ),
                  const SizedBox(width: PointageSpacing.xs),
                  Text(
                    '+${_formatDuration(overtimeHours!)} d\'heures supplémentaires',
                    style: PointageTextStyles.cardLabel.copyWith(
                      fontSize: 12,
                      color: PointageColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Calcule la valeur de progression (0.0 à 1.0)
  double _calculateProgressValue() {
    if (weeklyTarget.inMilliseconds == 0) return 0.0;

    final progress =
        weeklyWorkTime.inMilliseconds / weeklyTarget.inMilliseconds;
    return progress.clamp(0.0, 1.0);
  }

  /// Formate une durée en heures:minutes
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '${hours}h$minutes';
  }
}

/// Variante compacte pour l'affichage dans les dashboards
class CompactWeeklySummary extends StatelessWidget {
  final Duration weeklyWorkTime;
  final Duration weeklyTarget;

  const CompactWeeklySummary({
    super.key,
    required this.weeklyWorkTime,
    required this.weeklyTarget,
  });

  @override
  Widget build(BuildContext context) {
    final progressValue = weeklyTarget.inMilliseconds > 0
        ? (weeklyWorkTime.inMilliseconds / weeklyTarget.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;
    final isTargetReached = weeklyWorkTime >= weeklyTarget;

    return ModernInfoCardVariants.compact(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Semaine',
                style: PointageTextStyles.cardLabel.copyWith(
                  fontSize: 12,
                ),
              ),
              Text(
                '${(progressValue * 100).toInt()}%',
                style: PointageTextStyles.cardLabel.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isTargetReached
                      ? PointageColors.success
                      : PointageColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: PointageColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isTargetReached
                    ? PointageColors.success
                    : PointageColors.primary,
              ),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
