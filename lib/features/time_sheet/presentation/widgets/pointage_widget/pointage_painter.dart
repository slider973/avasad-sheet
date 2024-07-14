import 'dart:math';

import 'package:flutter/material.dart';

class TimerPainter extends CustomPainter {
  final double progression;

  TimerPainter({required this.progression});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Cercle de fond
    final backgroundPaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Progrès
    final progressPaint = Paint()
      ..color = const Color(0xFF81A263)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progression,
      false,
      progressPaint,
    );

    // Graduations
    final markerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 60; i++) {
      final angle = 2 * pi * i / 60 - pi / 2;
      final markerLength = i % 5 == 0 ? 15.0 : 5.0;
      canvas.drawLine(
        center +
            Offset(cos(angle) * (radius - markerLength),
                sin(angle) * (radius - markerLength)),
        center + Offset(cos(angle) * radius, sin(angle) * radius),
        markerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) =>
      progression != oldDelegate.progression;
}