import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_card.dart';

class PointageList extends StatelessWidget {
  final List<Map<String, dynamic>> pointages;
  final Function(Map<String, dynamic>) onModifier;

  const PointageList({
    Key? key,
    required this.pointages,
    required this.onModifier,
  }) : super(key: key);

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
        );
      },
    );
  }
}

