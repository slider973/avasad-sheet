import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_card.dart';

class PointageList extends StatelessWidget {
  final List<Map<String, dynamic>> pointages;
  final Function(Map<String, dynamic>) onModifier;

  const PointageList({
    super.key,
    required this.pointages,
    required this.onModifier,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pointages.length,
      itemBuilder: (context, index) {
        final pointage = pointages[index];
        return PointageCard(
          type: pointage['type'],
          heure: pointage['heure'],
          onModifier: () => onModifier(pointage),
        )
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
            .slideX(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutQuad);
      },
    );
  }
}
