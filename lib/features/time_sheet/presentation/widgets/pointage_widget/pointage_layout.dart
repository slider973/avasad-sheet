import 'package:flutter/material.dart';
import 'package:time_sheet/features/time_sheet/presentation/widgets/pointage_widget/pointage_boutton.dart';
import 'package:time_sheet/features/time_sheet/presentation/widgets/pointage_widget/pointage_list.dart';

import 'pointage_header.dart';
import 'pointage_timer.dart';

class PointageLayout extends StatelessWidget {
  final String etatActuel;
  final DateTime? dernierPointage;
  final DateTime selectedDate;
  final double progression;
  final List<Map<String, dynamic>> pointages;
  final VoidCallback onActionPointage;
  final Function(Map<String, dynamic>) onModifierPointage;

  const PointageLayout({
    Key? key,
    required this.etatActuel,
    required this.dernierPointage,
    required this.progression,
    required this.pointages,
    required this.onActionPointage,
    required this.onModifierPointage,
    required this.selectedDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PointageHeader(selectedDate: selectedDate),
          const SizedBox(height: 20),
          PointageTimer(
            etatActuel: etatActuel,
            dernierPointage: dernierPointage,
            progression: progression,
          ),
          const SizedBox(height: 20),
          PointageButton(
            etatActuel: etatActuel,
            onPressed: onActionPointage,
          ),
          const SizedBox(height: 20),
          PointageList(
            pointages: pointages,
            onModifier: onModifierPointage,
          ),
        ],
      ),
    );
  }
}
