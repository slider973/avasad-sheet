import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pointage_painter.dart';
import '../../../../../services/timer_service.dart';

class PointageTimer extends StatefulWidget {
  final String etatActuel;
  final DateTime? dernierPointage;
  final double progression;

  const PointageTimer({
    Key? key,
    required this.etatActuel,
    required this.dernierPointage,
    required this.progression,
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
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: TimerPainter(
                  lastProgression: _lastProgression,
                  currentProgression: widget.progression,
                  animation: _animation,
                  etatActuel: widget.etatActuel,
                ),
                size: const Size(250, 250),
              );
            },
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