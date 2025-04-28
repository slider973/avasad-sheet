import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pointage_painter.dart';
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

class _PointageTimerState extends State<PointageTimer> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late double _lastProgression;
  final TimerService _timerService = TimerService();
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastProgression = widget.progression;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
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
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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
    if (oldWidget.progression != widget.progression) {
      _lastProgression = oldWidget.progression;
      _animationController.forward(from: 0.0);
    }
    
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
  
  // Afficher un menu simple pour sélectionner un segment
  void _showSegmentSelectionMenu() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sélectionner une période'),
        children: [
          _buildSegmentOption('Entrée', Colors.teal),
          _buildSegmentOption('Pause', Color(0xFFE7D37F)),
          _buildSegmentOption('Reprise', Color(0xFFFD9B63)),
        ],
      ),
    );
  }
  
  // Construire une option de segment pour le menu
  Widget _buildSegmentOption(String type, Color color) {
    // Déterminer la durée en fonction du type et des pointages disponibles
    Duration duration = _getDurationForSegment(type);
    
    return SimpleDialogOption(
      onPressed: () {
        Navigator.of(context).pop();
        _showSegmentDetails(type, duration);
      },
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(type),
        ],
      ),
    );
  }
  
  // Obtenir la durée pour un type de segment donné
  Duration _getDurationForSegment(String segmentType) {
    // Durées par défaut
    Duration duration;
    if (segmentType == 'Entrée') {
      duration = Duration(hours: 4);
    } else if (segmentType == 'Pause') {
      duration = Duration(hours: 1);
    } else { // Reprise
      duration = Duration(hours: 5);
    }
    
    // Si nous avons des pointages, essayer de trouver la durée réelle
    if (widget.pointages.isNotEmpty) {
      // Trier les pointages par heure
      final sortedPointages = List<Map<String, dynamic>>.from(widget.pointages);
      sortedPointages.sort((a, b) => (a['heure'] as DateTime).compareTo(b['heure'] as DateTime));
      
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
      } else if (segmentType == 'Pause' && pauseStart != null && resumeStart != null) {
        duration = resumeStart.difference(pauseStart);
      } else if (segmentType == 'Reprise' && resumeStart != null && dayEnd != null) {
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
            Text('Type: $type', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Durée: ${_formatDuration(duration)}'),
            const SizedBox(height: 8),
            if (type == 'Entrée')
              const Text('Période du matin, de l\'arrivée jusqu\'à la pause déjeuner.'),
            if (type == 'Pause')
              const Text('Temps de pause, généralement pour le déjeuner.'),
            if (type == 'Reprise')
              const Text('Période de l\'après-midi, de la fin de la pause jusqu\'à la sortie.'),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Utiliser un InkWell au lieu de GestureDetector pour une meilleure détection des clics
          Material(
            color: Colors.transparent,
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () {
                // Afficher un menu simple pour sélectionner un segment
                _showSegmentSelectionMenu();
              },
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: TimerPainter(
                      lastProgression: _lastProgression,
                      currentProgression: widget.progression,
                      animation: _animation,
                      etatActuel: widget.etatActuel,
                      elapsedTime: _timerService.elapsedTime,
                      pointages: widget.pointages,
                      onSegmentTap: _showSegmentDetails,
                    ),
                    size: const Size(250, 250),
                  );
                },
              ),
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