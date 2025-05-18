import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../../services/timer_service.dart';

class PointageTimer extends StatefulWidget {
  final String etatActuel;
  final DateTime? dernierPointage;
  final double progression;
  final List<Map<String, dynamic>> pointages;

  const PointageTimer({
    Key? key,
    required this.etatActuel,
    required this.dernierPointage,
    required this.progression,
    required this.pointages,
  }) : super(key: key);

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

    // Créer un timer pour mettre à jour l'affichage
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
    // Afficher une boîte de dialogue avec les détails du segment
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - $type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: $type',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Durée: ${_formatDuration(duration)}'),
            const SizedBox(height: 8),
            if (type == 'Entrée')
              const Text(
                  'Période du matin, de l\'arrivée jusqu\'à la pause déjeuner.'),
            if (type == 'Pause')
              const Text('Temps de pause, généralement pour le déjeuner.'),
            if (type == 'Reprise')
              const Text(
                  'Période de l\'après-midi, de la fin de la pause jusqu\'à la sortie.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
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

  // Générer les sections du PieChart en fonction des pointages
  List<PieChartSectionData> _generateSections() {
    List<PieChartSectionData> sections = [];

    // Définir les couleurs des segments
    final Color entreeColor = Colors.teal;
    final Color pauseColor = const Color(0xFFE7D37F); // Jaune
    final Color repriseColor = const Color(0xFFFD9B63); // Orange
    
    // Définir les heures de la journée de travail (8h-18h = 10h)
    final startOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 8, 0); // 8h00
    final endOfDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 18, 0);  // 18h00
    final totalDaySeconds = endOfDay.difference(startOfDay).inSeconds.toDouble();
    
    // Extraire les horaires réels depuis les pointages
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

    // Cas spécial : si la journée est terminée (état Sortie), afficher le cercle complet avec la répartition réelle
    if (widget.etatActuel == 'Sortie' && entryTime != null && pauseStartTime != null && pauseEndTime != null && exitTime != null) {
      // Calcul proportionnel sur la vraie durée travaillée
      final totalWorkedSeconds = exitTime.difference(entryTime).inSeconds.toDouble();
      double entryPercent = (pauseStartTime.difference(entryTime).inSeconds.toDouble() / totalWorkedSeconds) * 100;
      double pausePercent = (pauseEndTime.difference(pauseStartTime).inSeconds.toDouble() / totalWorkedSeconds) * 100;
      double reprisePercent = (exitTime.difference(pauseEndTime).inSeconds.toDouble() / totalWorkedSeconds) * 100;
      sections.add(_buildSection(entreeColor, entryPercent, 0));
      sections.add(_buildSection(pauseColor, pausePercent, 1));
      sections.add(_buildSection(repriseColor, reprisePercent, 2));
      return sections;
    }

    // --- Remplissage dynamique selon l'étape et le temps réel écoulé ---
    if (entryTime != null && pauseStartTime == null) {
      // Entrée en cours (avant la pause)
      double entryPercent = (DateTime.now().difference(startOfDay).inSeconds.toDouble() / totalDaySeconds) * 100;
      entryPercent = entryPercent.clamp(0.0, 100.0);
      sections.add(_buildSection(entreeColor, entryPercent, 0));
      // Les autres segments restent à zéro
      return sections;
    } else if (entryTime != null && pauseStartTime != null && pauseEndTime == null) {
      // Pause en cours
      double entryPercent = (pauseStartTime.difference(startOfDay).inSeconds.toDouble() / totalDaySeconds) * 100;
      double pausePercent = (DateTime.now().difference(pauseStartTime).inSeconds.toDouble() / totalDaySeconds) * 100;
      // S'assurer que la limite supérieure est au moins 0
      double maxPausePercent = math.max(0.0, 100.0 - entryPercent);
      pausePercent = pausePercent.clamp(0.0, maxPausePercent);
      sections.add(_buildSection(entreeColor, entryPercent, 0));
      sections.add(_buildSection(pauseColor, pausePercent, 1));
      return sections;
    } else if (entryTime != null && pauseStartTime != null && pauseEndTime != null && exitTime == null) {
      // Reprise en cours
      double entryPercent = (pauseStartTime.difference(startOfDay).inSeconds.toDouble() / totalDaySeconds) * 100;
      double pausePercent = (pauseEndTime.difference(pauseStartTime).inSeconds.toDouble() / totalDaySeconds) * 100;
      double reprisePercent = (DateTime.now().difference(pauseEndTime).inSeconds.toDouble() / totalDaySeconds) * 100;
      // S'assurer que la limite supérieure est au moins 0
      double maxReprisePercent = math.max(0.0, 100.0 - entryPercent - pausePercent);
      reprisePercent = reprisePercent.clamp(0.0, maxReprisePercent);
      sections.add(_buildSection(entreeColor, entryPercent, 0));
      sections.add(_buildSection(pauseColor, pausePercent, 1));
      sections.add(_buildSection(repriseColor, reprisePercent, 2));
      return sections;
    }

    // Si aucun pointage ou état non commencé, ne rien afficher
    return [];
  }

  // Construire une section de PieChart avec animation au toucher
  PieChartSectionData _buildSection(Color color, double value, int index) {
    final isTouched = index == _touchedIndex;
    final double radius = isTouched ? 30 : 25;
    final double fontSize = isTouched ? 8 : 0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: isTouched ? '${value.toStringAsFixed(1)}%' : '',
      radius: radius,
      titleStyle: TextStyle(
          fontSize: fontSize, color: Colors.white, fontWeight: FontWeight.bold),
      badgeWidget: null,
      badgePositionPercentageOffset: 0,
      borderSide: const BorderSide(width: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Utiliser PieChart au lieu de CustomPainter
          SizedBox(
            width: 250,
            height: 250,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, _) {
                return PieChart(
                  PieChartData(
                    sections: _generateSections(),
                    centerSpaceRadius: 90,
                    sectionsSpace: 0.2,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (event is FlTapDownEvent ||
                              event is FlPanDownEvent) {
                            _touchedIndex = pieTouchResponse
                                    ?.touchedSection?.touchedSectionIndex ??
                                -1;
                          } else if (event is FlTapUpEvent ||
                              event is FlPanEndEvent ||
                              event is FlLongPressEnd) {
                            if (_touchedIndex != -1) {
                              // Déterminer quel segment a été touché
                              if (_touchedIndex == 0) {
                                _showSegmentDetails(
                                    'Entrée', _getDurationForSegment('Entrée'));
                              } else if (_touchedIndex == 1) {
                                _showSegmentDetails(
                                    'Pause', _getDurationForSegment('Pause'));
                              } else if (_touchedIndex == 2) {
                                _showSegmentDetails('Reprise',
                                    _getDurationForSegment('Reprise'));
                              }
                              _touchedIndex = -1;
                            }
                          } else {
                            _touchedIndex = -1;
                          }
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    startDegreeOffset: 270,
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
