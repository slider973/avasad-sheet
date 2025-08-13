import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../services/timer_service.dart';

// Classe personnalisée pour dessiner le timer
class TimerPainter extends CustomPainter {
  final String etatActuel;
  final List<Map<String, dynamic>> pointages;
  final int touchedIndex;
  
  TimerPainter({
    required this.etatActuel,
    required this.pointages,
    required this.touchedIndex,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final innerRadius = radius - 25; // Rayon intérieur pour créer l'anneau
    
    // Définir les couleurs des segments
    final Color entreeColor = Colors.teal;
    final Color pauseColor = const Color(0xFFE7D37F); // Jaune
    final Color repriseColor = const Color(0xFFFD9B63); // Orange
    
    // Extraire les horaires réels depuis les pointages
    DateTime? entryTime;
    DateTime? pauseStartTime;
    DateTime? pauseEndTime;
    DateTime? exitTime;
    
    for (var pointage in pointages) {
      final type = pointage['type'] as String;
      final time = pointage['heure'] as DateTime;
      if (type == 'Entrée') entryTime = time;
      if (type == 'Début pause') pauseStartTime = time;
      if (type == 'Fin pause') pauseEndTime = time;
      if (type == 'Fin de journée') exitTime = time;
    }
    
    // Ne pas dessiner de fond pour garder la transparence
    
    // Dessiner les segments en fonction de l'état
    if (etatActuel == 'Non commencé') {
      // Ne rien dessiner pour l'état non commencé
      return;
    }
    
    // Cas spécial : si la journée est terminée (état Sortie)
    if (etatActuel == 'Sortie' && entryTime != null && pauseStartTime != null && 
        pauseEndTime != null && exitTime != null) {
      // Calculer les angles pour chaque segment
      final totalWorkedSeconds = exitTime.difference(entryTime).inSeconds.toDouble();
      if (totalWorkedSeconds <= 0) return;
      
      final entryPercent = pauseStartTime.difference(entryTime).inSeconds.toDouble() / totalWorkedSeconds;
      final pausePercent = pauseEndTime.difference(pauseStartTime).inSeconds.toDouble() / totalWorkedSeconds;
      final reprisePercent = exitTime.difference(pauseEndTime).inSeconds.toDouble() / totalWorkedSeconds;
      
      // Dessiner les segments
      _drawSegment(canvas, center, radius, innerRadius, 0, entryPercent * 360, entreeColor, 0 == touchedIndex);
      _drawSegment(canvas, center, radius, innerRadius, entryPercent * 360, 
                  (entryPercent + pausePercent) * 360, pauseColor, 1 == touchedIndex);
      _drawSegment(canvas, center, radius, innerRadius, (entryPercent + pausePercent) * 360, 
                  (entryPercent + pausePercent + reprisePercent) * 360, repriseColor, 2 == touchedIndex);
    } 
    // Entrée en cours (avant la pause)
    else if (entryTime != null && pauseStartTime == null) {
      // Calculer le temps écoulé depuis l'entrée
      final now = DateTime.now();
      final elapsedSinceEntry = now.difference(entryTime);
      
      // Progression basée sur 4 heures de travail maximum pour l'affichage du segment
      final maxWorkingSeconds = 4 * 60 * 60; // 4 heures
      double entryPercent = elapsedSinceEntry.inSeconds / maxWorkingSeconds;
      entryPercent = math.min(1.0, math.max(0.0, entryPercent));
      
      // Dessiner le segment d'entrée qui se remplit progressivement
      _drawSegment(canvas, center, radius, innerRadius, 0, entryPercent * 360, entreeColor, 0 == touchedIndex);
    }
    // Pause en cours
    else if (entryTime != null && pauseStartTime != null && pauseEndTime == null) {
      final now = DateTime.now();
      
      // Calculer les durées réelles de travail
      final entryDuration = pauseStartTime.difference(entryTime);
      final pauseDuration = now.difference(pauseStartTime);
      
      // Segments proportionnels basés sur le temps réel écoulé
      final totalElapsed = entryDuration + pauseDuration;
      final totalSeconds = totalElapsed.inSeconds.toDouble();
      
      if (totalSeconds > 0) {
        double entryPercent = entryDuration.inSeconds / totalSeconds;
        double pausePercent = pauseDuration.inSeconds / totalSeconds;
        
        // Normaliser pour que le total fasse maximum 360° (cercle complet après 8h)
        final maxWorkingSeconds = 8 * 60 * 60; // 8 heures
        final progressRatio = math.min(1.0, totalSeconds / maxWorkingSeconds);
        
        entryPercent *= progressRatio;
        pausePercent *= progressRatio;
        
        // Dessiner les segments
        _drawSegment(canvas, center, radius, innerRadius, 0, entryPercent * 360, entreeColor, 0 == touchedIndex);
        _drawSegment(canvas, center, radius, innerRadius, entryPercent * 360, 
                    (entryPercent + pausePercent) * 360, pauseColor, 1 == touchedIndex);
      }
    }
    // Reprise en cours
    else if (entryTime != null && pauseStartTime != null && pauseEndTime != null && exitTime == null) {
      final now = DateTime.now();
      
      // Calculer les durées réelles de chaque phase
      final entryDuration = pauseStartTime.difference(entryTime);
      final pauseDuration = pauseEndTime.difference(pauseStartTime);
      final repriseDuration = now.difference(pauseEndTime);
      
      // Segments proportionnels basés sur le temps réel écoulé
      final totalElapsed = entryDuration + pauseDuration + repriseDuration;
      final totalSeconds = totalElapsed.inSeconds.toDouble();
      
      if (totalSeconds > 0) {
        double entryPercent = entryDuration.inSeconds / totalSeconds;
        double pausePercent = pauseDuration.inSeconds / totalSeconds;
        double reprisePercent = repriseDuration.inSeconds / totalSeconds;
        
        // Normaliser pour que le total fasse maximum 360° (cercle complet après 8h)
        final maxWorkingSeconds = 8 * 60 * 60; // 8 heures
        final progressRatio = math.min(1.0, totalSeconds / maxWorkingSeconds);
        
        entryPercent *= progressRatio;
        pausePercent *= progressRatio;
        reprisePercent *= progressRatio;
        
        // Dessiner les segments
        _drawSegment(canvas, center, radius, innerRadius, 0, entryPercent * 360, entreeColor, 0 == touchedIndex);
        _drawSegment(canvas, center, radius, innerRadius, entryPercent * 360, 
                    (entryPercent + pausePercent) * 360, pauseColor, 1 == touchedIndex);
        _drawSegment(canvas, center, radius, innerRadius, (entryPercent + pausePercent) * 360, 
                    (entryPercent + pausePercent + reprisePercent) * 360, repriseColor, 2 == touchedIndex);
      }
    }
  }
  
  // Méthode pour dessiner un segment d'arc
  void _drawSegment(Canvas canvas, Offset center, double radius, double innerRadius, 
                    double startAngle, double endAngle, Color color, bool isTouched) {
    final paint = Paint()
      ..color = isTouched ? color.withOpacity(0.8) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isTouched ? 30 : 25;
    
    // Convertir les angles en radians et ajuster pour commencer à midi (270 degrés)
    final startRad = (startAngle - 90) * math.pi / 180;
    final endRad = (endAngle - 90) * math.pi / 180;
    
    // Dessiner l'arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - paint.strokeWidth / 2),
      startRad,
      endRad - startRad,
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(TimerPainter oldDelegate) {
    return oldDelegate.etatActuel != etatActuel ||
           oldDelegate.pointages != pointages ||
           oldDelegate.touchedIndex != touchedIndex ||
           true; // Toujours repeindre pour la progression temps réel
  }
}

class PointageTimer extends StatefulWidget {
  final String etatActuel;
  final DateTime? dernierPointage;
  final double progression;
  final List<Map<String, dynamic>> pointages;

  const PointageTimer({
    super.key,
    required this.etatActuel,
    required this.dernierPointage,
    required this.progression,
    required this.pointages,
  });

  @override
  _PointageTimerState createState() => _PointageTimerState();
}

class _PointageTimerState extends State<PointageTimer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  final TimerService _timerService = TimerService();
  Timer? _updateTimer;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.forward();

    // Initialiser le service de timer
    _timerService.initialize(widget.etatActuel, widget.dernierPointage);

    // Créer un timer pour mettre à jour l'affichage du compteur temps réel
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // L'application passe en arrière-plan ou devient inactive
      _timerService.appPaused();
    } else if (state == AppLifecycleState.resumed) {
      // L'application revient au premier plan
      _timerService.appResumed();
      setState(() {}); // Forcer une mise à jour de l'affichage
    }
  }

  @override
  void didUpdateWidget(PointageTimer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si l'état a changé ou si le dernier pointage a changé
    if (oldWidget.etatActuel != widget.etatActuel ||
        oldWidget.dernierPointage != widget.dernierPointage) {
      // Mettre à jour l'état du timer dans le service
      _timerService.updateState(widget.etatActuel, widget.dernierPointage);
      setState(() {}); // Forcer une mise à jour de l'affichage
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // Obtenir la durée pour un type de segment donné
  Duration _getDurationForSegment(String segmentType) {
    // Durées par défaut
    Duration duration;
    if (segmentType == 'Entrée') {
      duration = Duration(hours: 4);
    } else if (segmentType == 'Pause') {
      duration = Duration(hours: 1);
    } else {
      // Reprise
      duration = Duration(hours: 5);
    }

    // Si nous avons des pointages, essayer de trouver la durée réelle
    if (widget.pointages.isNotEmpty) {
      // Trier les pointages par heure
      final sortedPointages = List<Map<String, dynamic>>.from(widget.pointages);
      sortedPointages.sort(
          (a, b) => (a['heure'] as DateTime).compareTo(b['heure'] as DateTime));

      // Trouver les durées réelles en fonction des pointages
      DateTime? entryStart, pauseStart, resumeStart, dayEnd;

      for (var pointage in sortedPointages) {
        final type = pointage['type'] as String;
        final time = pointage['heure'] as DateTime;

        if (type == 'Entrée') {
          entryStart = time;
        } else if (type == 'Début pause') {
          pauseStart = time;
        } else if (type == 'Fin pause') {
          resumeStart = time;
        } else if (type == 'Fin de journée') {
          dayEnd = time;
        }
      }

      // Calculer les durées réelles si possible
      if (segmentType == 'Entrée' && entryStart != null && pauseStart != null) {
        duration = pauseStart.difference(entryStart);
      } else if (segmentType == 'Pause' &&
          pauseStart != null &&
          resumeStart != null) {
        duration = resumeStart.difference(pauseStart);
      } else if (segmentType == 'Reprise' &&
          resumeStart != null &&
          dayEnd != null) {
        duration = dayEnd.difference(resumeStart);
      }
    }

    return duration;
  }

  void _showSegmentDetails(String type, Duration duration) {
    // Calculer le pourcentage en fonction du type et de la durée
    String percentage = '';
    
    // Extraire les horaires réels depuis les pointages
    DateTime? entryTime;
    DateTime? pauseStartTime;
    DateTime? pauseEndTime;
    DateTime? exitTime;
    
    for (var pointage in widget.pointages) {
      final pointageType = pointage['type'] as String;
      final time = pointage['heure'] as DateTime;
      if (pointageType == 'Entrée') entryTime = time;
      if (pointageType == 'Début pause') pauseStartTime = time;
      if (pointageType == 'Fin pause') pauseEndTime = time;
      if (pointageType == 'Fin de journée') exitTime = time;
    }
    
    // Calculer le pourcentage en fonction de l'état actuel
    if (widget.etatActuel == 'Sortie' && entryTime != null && exitTime != null) {
      final totalWorkedSeconds = exitTime.difference(entryTime).inSeconds.toDouble();
      
      if (type == 'Entrée' && pauseStartTime != null) {
        final entrySeconds = pauseStartTime.difference(entryTime).inSeconds.toDouble();
        final percent = (entrySeconds / totalWorkedSeconds) * 100;
        percentage = '${percent.toStringAsFixed(1)}%';
      } else if (type == 'Pause' && pauseStartTime != null && pauseEndTime != null) {
        final pauseSeconds = pauseEndTime.difference(pauseStartTime).inSeconds.toDouble();
        final percent = (pauseSeconds / totalWorkedSeconds) * 100;
        percentage = '${percent.toStringAsFixed(1)}%';
      } else if (type == 'Reprise' && pauseEndTime != null) {
        final repriseSeconds = exitTime.difference(pauseEndTime).inSeconds.toDouble();
        final percent = (repriseSeconds / totalWorkedSeconds) * 100;
        percentage = '${percent.toStringAsFixed(1)}%';
      }
    }
    
    // Afficher un SnackBar avec les détails et le pourcentage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$type: ${_formatDuration(duration)}'),
            if (percentage.isNotEmpty)
              Text(percentage, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Construire une section de PieChart avec animation au toucher


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Utiliser CustomPaint au lieu de PieChart pour plus de stabilité
          SizedBox(
            width: 250,
            height: 250,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return CustomPaint(
                  painter: TimerPainter(
                    etatActuel: widget.etatActuel,
                    pointages: widget.pointages,
                    touchedIndex: _touchedIndex,
                  ),
                  child: GestureDetector(
                    onTapDown: (details) {
                      // Calculer l'angle du toucher par rapport au centre
                      final center = Offset(125, 125);
                      final touchPosition = details.localPosition;
                      final dx = touchPosition.dx - center.dx;
                      final dy = touchPosition.dy - center.dy;
                      
                      // Vérifier d'abord si le clic est dans le cercle (distance du centre)
                      final distance = math.sqrt(dx * dx + dy * dy);
                      final radius = 125 - 25; // Rayon du cercle moins la moitié de l'épaisseur du trait
                      
                      if (distance > radius + 15 || distance < radius - 15) {
                        // Clic en dehors de l'anneau du timer
                        setState(() {
                          _touchedIndex = -1;
                        });
                        return;
                      }
                      
                      // Calculer l'angle en degrés (0 = haut, sens horaire)
                      final angle = (math.atan2(dy, dx) * 180 / math.pi + 90) % 360;
                      
                      // Extraire les horaires réels depuis les pointages pour calculer les angles réels
                      DateTime? entryTime;
                      DateTime? pauseStartTime;
                      DateTime? pauseEndTime;
                      DateTime? exitTime;
                      
                      for (var pointage in widget.pointages) {
                        final type = pointage['type'] as String;
                        final time = pointage['heure'] as DateTime;
                        if (type == 'Entrée') entryTime = time;
                        if (type == 'Début pause') pauseStartTime = time;
                        if (type == 'Fin pause') pauseEndTime = time;
                        if (type == 'Fin de journée') exitTime = time;
                      }
                      
                      // Déterminer quel segment a été touché en fonction de l'angle et de l'état
                      setState(() {
                        if (widget.etatActuel == 'Sortie' && entryTime != null && pauseStartTime != null && 
                            pauseEndTime != null && exitTime != null) {
                          // Calculer les angles pour chaque segment
                          final totalWorkedSeconds = exitTime.difference(entryTime).inSeconds.toDouble();
                          if (totalWorkedSeconds <= 0) return;
                          
                          final entryPercent = pauseStartTime.difference(entryTime).inSeconds.toDouble() / totalWorkedSeconds;
                          final pausePercent = pauseEndTime.difference(pauseStartTime).inSeconds.toDouble() / totalWorkedSeconds;
                          
                          final entryEndAngle = entryPercent * 360;
                          final pauseEndAngle = entryEndAngle + (pausePercent * 360);
                          
                          if (angle < entryEndAngle) {
                            _touchedIndex = 0; // Entrée
                          } else if (angle < pauseEndAngle) {
                            _touchedIndex = 1; // Pause
                          } else {
                            _touchedIndex = 2; // Reprise
                          }
                        } else {
                          // Utiliser une division simple pour les autres états
                          if (angle < 120) {
                            _touchedIndex = 0; // Entrée
                          } else if (angle < 240) {
                            _touchedIndex = 1; // Pause
                          } else {
                            _touchedIndex = 2; // Reprise
                          }
                        }
                      });
                    },
                    onLongPress: () {
                      // Afficher immédiatement les détails lors d'un appui long
                      if (_touchedIndex != -1) {
                        if (_touchedIndex == 0) {
                          _showSegmentDetails('Entrée', _getDurationForSegment('Entrée'));
                        } else if (_touchedIndex == 1) {
                          _showSegmentDetails('Pause', _getDurationForSegment('Pause'));
                        } else if (_touchedIndex == 2) {
                          _showSegmentDetails('Reprise', _getDurationForSegment('Reprise'));
                        }
                      }
                    },
                    onTapUp: (details) {
                      if (_touchedIndex != -1) {
                        // Déterminer quel segment a été touché
                        if (_touchedIndex == 0) {
                          _showSegmentDetails('Entrée', _getDurationForSegment('Entrée'));
                        } else if (_touchedIndex == 1) {
                          _showSegmentDetails('Pause', _getDurationForSegment('Pause'));
                        } else if (_touchedIndex == 2) {
                          _showSegmentDetails('Reprise', _getDurationForSegment('Reprise'));
                        }
                        setState(() {
                          _touchedIndex = -1;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.etatActuel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.dernierPointage != null
                    ? DateFormat('HH:mm').format(widget.dernierPointage!)
                    : '00:00',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E50),
                ),
              ),
              if (widget.dernierPointage != null &&
                  widget.etatActuel != 'Non commencé' &&
                  widget.etatActuel != 'Sortie')
                Text(
                  'Durée: ${_formatDuration(_timerService.elapsedTime)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3E50),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
