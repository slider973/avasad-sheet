import 'dart:math';
import 'package:flutter/material.dart';

class TimerPainter extends CustomPainter {
  final double lastProgression;
  final double currentProgression;
  final Animation<double> animation;
  final String etatActuel;
  final Duration elapsedTime;
  final List<Map<String, dynamic>> pointages;
  final Function(String type, Duration duration)? onSegmentTap;

  // Stocker les segments pour la détection des clics
  final List<Map<String, dynamic>> _segments = [];
  
  // Stocker la taille du dernier dessin pour hitTest
  Size? _lastSize;

  TimerPainter({
    required this.lastProgression,
    required this.currentProgression,
    required this.animation,
    required this.etatActuel,
    required this.elapsedTime,
    required this.pointages,
    this.onSegmentTap,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // Stocker la taille pour hitTest
    _lastSize = size;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // Vider la liste des segments
    _segments.clear();

    // Récupérer l'heure actuelle
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 8, 0); // 8h00 début de journée
    final endOfDay = DateTime(now.year, now.month, now.day, 18, 0);  // 18h00 fin de journée
    final totalDayDuration = endOfDay.difference(startOfDay).inSeconds;

    // Calculer la progression réelle basée sur le temps écoulé
    double realProgression = 0.0;
    
    if (etatActuel != 'Non commencé' && etatActuel != 'Sortie') {
      // Si on est en activité, calculer la progression basée sur le temps écoulé
      realProgression = elapsedTime.inSeconds / totalDayDuration;
      // Limiter à 1.0 maximum
      realProgression = min(1.0, realProgression);
    } else if (etatActuel == 'Sortie') {
      // Si on a terminé la journée, utiliser la progression complète
      realProgression = 1.0;
    }

    // Calcul de la progression animée
    final animatedProgression = lastProgression + (realProgression - lastProgression) * animation.value;
    
    // Définir les types et couleurs des segments
    final Map<String, Color> segmentColors = {
      'Entrée': Colors.teal,
      'Pause': Color(0xFFE7D37F),
      'Reprise': Color(0xFFFD9B63),
    };
    
    // Si nous avons des pointages, créer des segments basés sur les données réelles
    if (pointages.isNotEmpty) {
      // Trier les pointages par heure
      final sortedPointages = List<Map<String, dynamic>>.from(pointages);
      sortedPointages.sort((a, b) => (a['heure'] as DateTime).compareTo(b['heure'] as DateTime));
      
      // Créer des segments basés sur les pointages
      String? currentType;
      DateTime? startTime;
      
      for (var pointage in sortedPointages) {
        final type = pointage['type'] as String;
        final time = pointage['heure'] as DateTime;
        
        if (type == 'Entrée') {
          currentType = 'Entrée';
          startTime = time;
        } else if (type == 'Début pause' && startTime != null) {
          // Fin du segment d'entrée, début de la pause
          final startProgress = startTime.difference(startOfDay).inSeconds / totalDayDuration;
          final endProgress = time.difference(startOfDay).inSeconds / totalDayDuration;
          final duration = time.difference(startTime);
          
          _segments.add({
            'type': currentType!,
            'startAngle': -pi / 2 + startProgress * 2 * pi,
            'sweepAngle': (endProgress - startProgress) * 2 * pi,
            'color': segmentColors[currentType] ?? Colors.grey,
            'duration': duration,
          });
          
          currentType = 'Pause';
          startTime = time;
        } else if (type == 'Fin pause' && startTime != null) {
          // Fin du segment de pause, début de la reprise
          final startProgress = startTime.difference(startOfDay).inSeconds / totalDayDuration;
          final endProgress = time.difference(startOfDay).inSeconds / totalDayDuration;
          final duration = time.difference(startTime);
          
          _segments.add({
            'type': currentType!,
            'startAngle': -pi / 2 + startProgress * 2 * pi,
            'sweepAngle': (endProgress - startProgress) * 2 * pi,
            'color': segmentColors[currentType] ?? Colors.grey,
            'duration': duration,
          });
          
          currentType = 'Reprise';
          startTime = time;
        } else if (type == 'Fin de journée' && startTime != null) {
          // Fin du dernier segment
          final startProgress = startTime.difference(startOfDay).inSeconds / totalDayDuration;
          final endProgress = time.difference(startOfDay).inSeconds / totalDayDuration;
          final duration = time.difference(startTime);
          
          _segments.add({
            'type': currentType!,
            'startAngle': -pi / 2 + startProgress * 2 * pi,
            'sweepAngle': (endProgress - startProgress) * 2 * pi,
            'color': segmentColors[currentType] ?? Colors.grey,
            'duration': duration,
          });
        }
      }
      
      // Si on est en cours de journée (pas terminé), ajouter le segment en cours jusqu'à maintenant
      if (etatActuel != 'Non commencé' && etatActuel != 'Sortie' && startTime != null) {
        final startProgress = startTime.difference(startOfDay).inSeconds / totalDayDuration;
        final endProgress = now.difference(startOfDay).inSeconds / totalDayDuration;
        final duration = now.difference(startTime);
        
        _segments.add({
          'type': currentType!,
          'startAngle': -pi / 2 + startProgress * 2 * pi,
          'sweepAngle': (endProgress - startProgress) * 2 * pi,
          'color': segmentColors[currentType] ?? Colors.grey,
          'duration': duration,
        });
      }
    } else {
      // Si pas de pointages, utiliser les segments par défaut
      final colors = [
        Colors.teal,
        Color(0xFFE7D37F),
        Color(0xFFFD9B63),
      ];
      
      final types = ['Entrée', 'Pause', 'Reprise'];
      
      for (int i = 0; i < colors.length; i++) {
        final sweepAngle = 2 * pi / colors.length;
        final startAngle = -pi / 2 + i * sweepAngle;
        
        _segments.add({
          'type': types[i],
          'startAngle': startAngle,
          'sweepAngle': sweepAngle,
          'color': colors[i],
          'duration': Duration(hours: i == 0 ? 4 : (i == 1 ? 1 : 5)), // Durées estimées
        });
      }
    }
    
    // Dessiner les segments avec animation
    for (var segment in _segments) {
      final startAngle = segment['startAngle'] as double;
      final sweepAngle = segment['sweepAngle'] as double;
      final color = segment['color'] as Color;
      
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      
      // Calculer l'angle de progression animé
      final endAngle = startAngle + sweepAngle;
      final progressEndAngle = min(-pi/2 + animatedProgression * 2 * pi, endAngle);
      
      if (progressEndAngle > startAngle) {
        final progressSweepAngle = progressEndAngle - startAngle;
        
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius - 10),
          startAngle,
          progressSweepAngle,
          false,
          paint,
        );
      }
    }

    // Cercle blanc central
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 30, whitePaint);

    // Points sur le cercle
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 60; i++) {
      final angle = 2 * pi * i / 60 - pi / 2;
      final dotCenter = Offset(
          center.dx + (radius - 20) * cos(angle),
          center.dy + (radius - 20) * sin(angle)
      );
      canvas.drawCircle(dotCenter, 2, dotPaint);
    }
  }

  // Méthode pour détecter les clics sur les segments
  @override
  bool? hitTest(Offset position) {
    // Vérifier si nous avons une taille valide
    if (_lastSize == null) return false;
    
    final Size size = _lastSize!;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // Calculer la distance du centre
    final distance = (position - center).distance;
    
    // Vérifier si le clic est dans l'anneau du timer (entre radius-30 et radius-10)
    if (distance >= radius - 30 && distance <= radius - 10) {
      // Calculer l'angle du clic
      final angle = atan2(position.dy - center.dy, position.dx - center.dx);
      
      // Normaliser l'angle pour qu'il soit entre -pi/2 et 3pi/2
      double normalizedAngle = angle;
      if (normalizedAngle < -pi/2) normalizedAngle += 2 * pi;
      
      // Vérifier quel segment a été cliqué
      for (var segment in _segments) {
        final startAngle = segment['startAngle'] as double;
        final sweepAngle = segment['sweepAngle'] as double;
        final endAngle = startAngle + sweepAngle;
        
        if (normalizedAngle >= startAngle && normalizedAngle <= endAngle) {
          if (onSegmentTap != null) {
            onSegmentTap!(segment['type'] as String, segment['duration'] as Duration);
          }
          return true;
        }
      }
    }
    return false;
  }
  
  @override
  bool shouldRepaint(TimerPainter oldDelegate) =>
      lastProgression != oldDelegate.lastProgression ||
      currentProgression != oldDelegate.currentProgression ||
      animation != oldDelegate.animation ||
      etatActuel != oldDelegate.etatActuel ||
      elapsedTime != oldDelegate.elapsedTime ||
      pointages != oldDelegate.pointages;
}