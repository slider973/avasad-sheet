import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pointage_painter.dart';

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

class _PointageTimerState extends State<PointageTimer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late double _lastProgression;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _lastProgression = widget.progression;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Initialiser avec un temps écoulé de zéro
    _elapsedTime = Duration.zero;
  }

  DateTime? _startTime;

  void _startTimer() {
    _timer?.cancel();
    
    // Réinitialiser le temps écoulé
    setState(() {
      _elapsedTime = Duration.zero;
    });
    
    // Ne démarrer le timer que si on a déjà pointé
    if (widget.dernierPointage == null || widget.etatActuel == 'Non commencé') {
      _startTime = null;
      return;
    }
    
    // Initialiser le temps de départ au moment où le timer est lancé
    _startTime = DateTime.now();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.etatActuel != 'Non commencé' && widget.etatActuel != 'Sortie') {
        setState(() {
          // Si on est en pause, on ne compte pas le temps
          if (widget.etatActuel == 'Pause') {
            _startTime = null;
            _elapsedTime = Duration.zero;
            return;
          }
          
          // Calculer le temps écoulé en excluant les pauses
          if (_startTime != null && (widget.etatActuel == 'Entrée' || widget.etatActuel == 'Reprise')) {
            _elapsedTime = DateTime.now().difference(_startTime!);
          } else {
            _elapsedTime = Duration.zero;
          }
        });
      }
    });
  }

  @override
  void didUpdateWidget(PointageTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progression != widget.progression) {
      _lastProgression = oldWidget.progression;
      _animationController.forward(from: 0.0);
    }
    if (oldWidget.dernierPointage != widget.dernierPointage) {
      _elapsedTime = Duration.zero;
      _startTimer();
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
    _timer?.cancel();
    _animationController.dispose();
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
                  'Durée: ${_formatDuration(_elapsedTime)}',
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