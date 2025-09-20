import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: _getIconColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Fin de journée estimée',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estimatedEndTime != null
                          ? DateFormat('HH:mm').format(estimatedEndTime)
                          : '--:--',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getTimeColor(),
                      ),
                    ),
                    if (remainingWorkTime > Duration.zero)
                      Text(
                        'Il reste ${_formatDuration(remainingWorkTime)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                if (widget.currentState == 'Pause')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pause_circle_outline,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En pause',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
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
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Objectif journalier atteint',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
    if (_isInOvertime()) return Colors.green.shade600;
    if (widget.currentState == 'Pause') return Colors.orange.shade600;
    return Colors.blue.shade600;
  }

  /// Couleur du temps selon l'état
  Color _getTimeColor() {
    if (_isInOvertime()) return Colors.green.shade700;
    if (widget.currentState == 'Pause') return Colors.orange.shade700;
    return Colors.grey.shade800;
  }

  /// Formate une durée en heures:minutes
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return '$hours:$minutes';
  }
}
