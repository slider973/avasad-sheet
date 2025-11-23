import 'package:flutter/material.dart';
import 'modern_info_card.dart';
import 'pointage_design_system.dart';

/// Card qui affiche l'objectif journalier avec indicateur de progression
class DailyObjectiveCard extends StatelessWidget {
  final List<Map<String, dynamic>> pointages;
  final String currentState;
  final Duration targetWorkDuration;
  final Duration? currentWorkTime;

  const DailyObjectiveCard({
    super.key,
    required this.pointages,
    required this.currentState,
    this.targetWorkDuration = const Duration(hours: 8, minutes: 18),
    this.currentWorkTime,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWorkTime = currentWorkTime ?? _calculateEffectiveWorkTime();
    final progressValue = _calculateProgressValue(effectiveWorkTime);
    final isObjectiveReached = effectiveWorkTime >= targetWorkDuration;

    // Ne pas afficher la card si pas encore commencé
    if (currentState == 'Non commencé' || pointages.isEmpty) {
      return const SizedBox.shrink();
    }

    return ModernInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isObjectiveReached
                    ? Icons.check_circle_outline
                    : Icons.radio_button_unchecked,
                color: isObjectiveReached
                    ? PointageColors.success
                    : PointageColors.textSecondary,
                size: 24,
              ),
              const SizedBox(width: PointageSpacing.sm),
              Expanded(
                child: Text(
                  isObjectiveReached
                      ? 'Objectif journalier atteint'
                      : 'Objectif journalier',
                  style: PointageTextStyles.cardLabel.copyWith(
                    color: isObjectiveReached
                        ? PointageColors.success
                        : PointageColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(effectiveWorkTime),
                style: PointageTextStyles.cardValue.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isObjectiveReached
                      ? PointageColors.success
                      : PointageColors.primary,
                ),
              ),
              Text(
                '/ ${_formatDuration(targetWorkDuration)}',
                style: PointageTextStyles.cardLabel,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: PointageColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                isObjectiveReached
                    ? PointageColors.success
                    : PointageColors.primary,
              ),
              minHeight: 6,
            ),
          ),
          if (!isObjectiveReached && currentState != 'Sortie')
            Padding(
              padding: const EdgeInsets.only(top: PointageSpacing.xs),
              child: Text(
                'Il reste ${_formatDuration(targetWorkDuration - effectiveWorkTime)}',
                style: PointageTextStyles.cardLabel.copyWith(
                  fontSize: 12,
                ),
              ),
            ),
          if (isObjectiveReached && effectiveWorkTime > targetWorkDuration)
            Padding(
              padding: const EdgeInsets.only(top: PointageSpacing.xs),
              child: Text(
                '+${_formatDuration(effectiveWorkTime - targetWorkDuration)} d\'heures supplémentaires',
                style: PointageTextStyles.cardLabel.copyWith(
                  fontSize: 12,
                  color: PointageColors.success,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Calcule le temps de travail effectif (sans les pauses)
  Duration _calculateEffectiveWorkTime() {
    Duration totalDuration = Duration.zero;
    DateTime? workStart;

    for (var pointage in pointages) {
      String type = pointage['type'];
      DateTime time = pointage['heure'];

      switch (type) {
        case 'Entrée':
          workStart = time;
          break;
        case 'Début pause':
          if (workStart != null) {
            totalDuration += time.difference(workStart);
          }
          workStart = null;
          break;
        case 'Fin pause':
          workStart = time;
          break;
        case 'Fin de journée':
          if (workStart != null) {
            totalDuration += time.difference(workStart);
          }
          workStart = null;
          break;
      }
    }

    // Si actuellement en train de travailler, ajouter le temps depuis le dernier pointage
    if (workStart != null &&
        (currentState == 'Entrée' || currentState == 'Reprise')) {
      totalDuration += DateTime.now().difference(workStart);
    }

    return totalDuration;
  }

  /// Calcule la valeur de progression (0.0 à 1.0)
  double _calculateProgressValue(Duration effectiveWorkTime) {
    if (targetWorkDuration.inMilliseconds == 0) return 0.0;

    final progress =
        effectiveWorkTime.inMilliseconds / targetWorkDuration.inMilliseconds;
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
