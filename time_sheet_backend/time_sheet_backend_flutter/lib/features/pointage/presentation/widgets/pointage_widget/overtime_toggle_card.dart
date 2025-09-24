import 'package:flutter/material.dart';
import 'modern_info_card.dart';
import 'pointage_design_system.dart';

/// Card modernisée pour le toggle des heures supplémentaires
class OvertimeToggleCard extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;
  final String? description;
  final bool isEnabled;

  const OvertimeToggleCard({
    super.key,
    required this.isActive,
    required this.onToggle,
    this.description,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernInfoCard(
      onTap: isEnabled ? onToggle : null,
      isInteractive: isEnabled,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? PointageColors.warning.withValues(alpha: 0.1)
                  : PointageColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time_filled,
              color: isActive
                  ? PointageColors.warning
                  : PointageColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heures supplémentaires',
                  style: PointageTextStyles.cardLabel.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? PointageColors.warning
                        : PointageColors.textSecondary,
                  ),
                ),
                if (description != null)
                  Text(
                    description!,
                    style: PointageTextStyles.cardLabel.copyWith(
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            onChanged: isEnabled ? (_) => onToggle() : null,
            activeThumbColor: PointageColors.warning,
            inactiveThumbColor: PointageColors.textSecondary,
            inactiveTrackColor:
                PointageColors.textSecondary.withValues(alpha: 0.3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

/// Variante compacte pour l'affichage dans les listes
class CompactOvertimeToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;
  final bool isEnabled;

  const CompactOvertimeToggle({
    super.key,
    required this.isActive,
    required this.onToggle,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time_filled,
          color:
              isActive ? PointageColors.warning : PointageColors.textSecondary,
          size: 16,
        ),
        const SizedBox(width: PointageSpacing.xs),
        Text(
          'HS',
          style: PointageTextStyles.cardLabel.copyWith(
            color: isActive
                ? PointageColors.warning
                : PointageColors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: PointageSpacing.xs),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isActive,
            onChanged: isEnabled ? (_) => onToggle() : null,
            activeThumbColor: PointageColors.warning,
            inactiveThumbColor: PointageColors.textSecondary,
            inactiveTrackColor:
                PointageColors.textSecondary.withValues(alpha: 0.3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
