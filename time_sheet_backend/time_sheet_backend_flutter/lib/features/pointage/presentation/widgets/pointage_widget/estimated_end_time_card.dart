import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'modern_info_card.dart';
import 'pointage_design_system.dart';

/// Card qui affiche l'heure de fin estimée en se réajustant automatiquement
/// en fonction du temps de pause et du temps de travail effectué
class EstimatedEndTimeCard extends StatefulWidget {
  final List<Map<String, dynamic>> pointages;
  final String currentState;
  final Duration targetWorkDuration;

  const EstimatedEndTimeCard({
    super.key,
    required this.pointages,
    required this.currentState,
    this.targetWorkDuration = const Duration(hours: 8),
  });

  @override
  State<EstimatedEndTimeCard> createState() => _EstimatedEndTimeCardState();
}

class _EstimatedEndTimeCardState extends State<EstimatedEndTimeCard> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Mettre à jour toutes les 30 secondes pour un affichage en temps réel
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estimatedEndTime = _calculateEstimatedEndTime();
    final remainingWorkTime = _calculateRemainingWorkTime();

    // Ne pas afficher la card si pas encore commencé ou déjà terminé
    if (widget.currentState == 'Non commencé' ||
        widget.currentState == 'Sortie' ||
        widget.pointages.isEmpty) {
      return const SizedBox.shrink();
    }

    return ModernInfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: _getIconColor(),
                size: 24,
              ),
              const SizedBox(width: PointageSpacing.sm),
              Text(
                'Fin de journée estimée',
                style: PointageTextStyles.cardLabel,
              ),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estimatedEndTime != null
                          ? DateFormat('HH:mm').format(estimatedEndTime)
                          : '--:--',
                      style: PointageTextStyles.cardValue.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getTimeColor(),
                      ),
                    ),
                    if (remainingWorkTime > Duration.zero)
                      Text(
                        'Il reste ${_formatDuration(remainingWorkTime)}',
                        style: PointageTextStyles.cardLabel.copyWith(
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.currentState == 'Pause')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: PointageSpacing.sm,
                    vertical: PointageSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: PointageColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause_circle_outline,
                        size: 16,
                        color: PointageColors.warning,
                      ),
                      const SizedBox(width: PointageSpacing.xs),
                      Text(
                        'En pause',
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
          if (_isInOvertime())
            Container(
              margin: const EdgeInsets.only(top: PointageSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: PointageSpacing.sm,
                vertical: PointageSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: PointageColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: PointageColors.success,
                  ),
                  const SizedBox(width: PointageSpacing.xs),
                  Text(
                    'Objectif journalier atteint',
                    style: PointageTextStyles.cardLabel.copyWith(
                      fontSize: 12,
                      color: PointageColors.success,
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

  /// Calcule l'heure de fin estimée en tenant compte des pauses
  DateTime? _calculateEstimatedEndTime() {
    if (widget.pointages.isEmpty) return null;

    final workStartTime = widget.pointages.first['heure'] as DateTime;
    final effectiveWorkTime = _calculateEffectiveWorkTime();
    final totalBreakTime = _calculateTotalBreakTime();
    final remainingWorkTime = _calculateRemainingWorkTime();

    if (remainingWorkTime <= Duration.zero) {
      // Objectif déjà atteint
      return null;
    }

    // Temps total nécessaire = temps déjà travaillé + temps restant + pauses déjà prises + pause actuelle
    Duration totalTimeNeeded =
        effectiveWorkTime + remainingWorkTime + totalBreakTime;

    // Si en pause, ajouter le temps de pause actuel
    if (widget.currentState == 'Pause') {
      final currentBreakTime = _getCurrentBreakTime();
      totalTimeNeeded += currentBreakTime;
    }

    return workStartTime.add(totalTimeNeeded);
  }

  /// Calcule le temps de travail effectif (sans les pauses)
  Duration _calculateEffectiveWorkTime() {
    Duration totalDuration = Duration.zero;
    DateTime? workStart;

    for (var pointage in widget.pointages) {
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
        (widget.currentState == 'Entrée' || widget.currentState == 'Reprise')) {
      totalDuration += DateTime.now().difference(workStart);
    }

    return totalDuration;
  }

  /// Calcule le temps de pause total
  Duration _calculateTotalBreakTime() {
    Duration totalBreakDuration = Duration.zero;
    DateTime? pauseStart;

    for (var pointage in widget.pointages) {
      String type = pointage['type'];
      DateTime time = pointage['heure'];

      switch (type) {
        case 'Début pause':
          pauseStart = time;
          break;
        case 'Fin pause':
          if (pauseStart != null) {
            totalBreakDuration += time.difference(pauseStart);
            pauseStart = null;
          }
          break;
      }
    }

    return totalBreakDuration;
  }

  /// Calcule le temps de pause actuel si en pause
  Duration _getCurrentBreakTime() {
    if (widget.currentState != 'Pause') return Duration.zero;

    // Trouver le dernier début de pause
    for (int i = widget.pointages.length - 1; i >= 0; i--) {
      if (widget.pointages[i]['type'] == 'Début pause') {
        DateTime pauseStart = widget.pointages[i]['heure'];
        return DateTime.now().difference(pauseStart);
      }
    }

    return Duration.zero;
  }

  /// Calcule le temps de travail restant pour atteindre l'objectif
  Duration _calculateRemainingWorkTime() {
    final effectiveWorkTime = _calculateEffectiveWorkTime();
    if (effectiveWorkTime >= widget.targetWorkDuration) {
      return Duration.zero;
    }
    return widget.targetWorkDuration - effectiveWorkTime;
  }

  /// Vérifie si on est en heures supplémentaires
  bool _isInOvertime() {
    return _calculateEffectiveWorkTime() >= widget.targetWorkDuration;
  }

  /// Couleur de l'icône selon l'état
  Color _getIconColor() {
    if (_isInOvertime()) return PointageColors.success;
    if (widget.currentState == 'Pause') return PointageColors.warning;
    return PointageColors.primary;
  }

  /// Couleur du temps selon l'état
  Color _getTimeColor() {
    if (_isInOvertime()) return PointageColors.success;
    if (widget.currentState == 'Pause') return PointageColors.warning;
    return PointageColors.primary;
  }

  /// Formate une durée en heures:minutes
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes';
  }
}
