import 'package:flutter/material.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_absence.dart';

import '../../../../absence/domain/value_objects/absence_type.dart';
import 'pointage_absence_bouton_form.dart';

class PointageAbsenceBouton extends StatelessWidget {
  final Function(DateTime, DateTime, String, AbsenceType, String, String, TimeOfDay?, TimeOfDay?)
      onSignalerAbsencePeriode;
  final String etatActuel;
  final DateTime selectedDate;

  const PointageAbsenceBouton(
      {super.key, required this.onSignalerAbsencePeriode, required this.etatActuel, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    if (etatActuel == 'Sortie') {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 320,
      height: 40,
      child: ElevatedButton(
        onPressed: () => _showAbsenceBottomSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Signaler une absence',
          style: TextStyle(fontSize: 15),
        ),
      ),
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
            top: Radius.circular(20), // Arrondir uniquement les coins du haut
          ),
          child: Container(
            color: Colors.white, // Couleur de fond du contenu
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
