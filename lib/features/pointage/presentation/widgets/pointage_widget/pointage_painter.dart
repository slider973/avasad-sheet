import 'dart:math';
import 'package:flutter/material.dart';

class TimerPainter extends CustomPainter {
  final double lastProgression;
  final double currentProgression;
  final Animation<double> animation;
  final String etatActuel;

  TimerPainter({
    required this.lastProgression,
    required this.currentProgression,
    required this.animation,
    required this.etatActuel
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Liste des couleurs pour chaque segment
    final colors = [
      Colors.teal,
      Color(0xFF365E32),
      Color(0xFF81A263),
      Color(0xFFE7D37F),
      Color(0xFFFD9B63),
    ];

    // Calcul de la progression animée
    final animatedProgression = lastProgression + (currentProgression - lastProgression) * animation.value;

    // Dessin des segments colorés avec animation
    for (int i = 0; i < colors.length; i++) {
      final sweepAngle = 2 * pi / colors.length;
      final startAngle = -pi / 2 + i * sweepAngle;

      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;

      final progressAngle = min(sweepAngle, max(0.0, animatedProgression * 2 * pi - i * sweepAngle));

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        progressAngle.toDouble(),
        false,
        paint,
      );
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

  @override
  bool shouldRepaint(TimerPainter oldDelegate) =>
      lastProgression != oldDelegate.lastProgression ||
          currentProgression != oldDelegate.currentProgression ||
          animation != oldDelegate.animation ||
          etatActuel != oldDelegate.etatActuel;
}