import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/time_sheet/presentation/widgets/pointage_widget/pointage_painter.dart';

class PointageTimer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: TimerPainter(progression: progression),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                etatActuel,
                style: const TextStyle(fontSize: 18),
              ),
              Text(
                dernierPointage != null
                    ? DateFormat('HH:mm').format(dernierPointage!)
                    : '00:00',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}