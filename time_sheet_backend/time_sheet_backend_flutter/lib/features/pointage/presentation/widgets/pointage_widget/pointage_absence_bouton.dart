import 'package:flutter/material.dart';

import '../../../../absence/domain/value_objects/absence_type.dart';
import 'pointage_absence_bouton_form.dart';
import 'modern_pointage_button.dart';
import 'pointage_design_system.dart';

class PointageAbsenceBouton extends StatelessWidget {
  final Function(DateTime, DateTime, String, AbsenceType, String, String,
      TimeOfDay?, TimeOfDay?) onSignalerAbsencePeriode;
  final String etatActuel;
  final DateTime selectedDate;

  const PointageAbsenceBouton(
      {super.key,
      required this.onSignalerAbsencePeriode,
      required this.etatActuel,
      required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    if (etatActuel == 'Sortie') {
      return const SizedBox.shrink();
    }

    return ModernPointageButton.secondary(
      text: 'Signaler une absence',
      onPressed: () => _showAbsenceBottomSheet(context),
      icon: Icons.event_busy,
    );
  }

  void _showAbsenceBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(
        maxWidth: 450,
        maxHeight: 800,
      ),
      builder: (BuildContext context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: Container(
            color: PointageColors.cardBackground,
            child: AbsenceForm(
              selectedDate: selectedDate,
              onSignalerAbsencePeriode: onSignalerAbsencePeriode,
            ),
          ),
        );
      },
    );
  }
}
