import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_remove_timesheet_day.dart';

class PointageAbsence extends StatelessWidget {
  final String? absenceReason;
  final VoidCallback onDeleteEntry;
  final String etatActuel;

  const PointageAbsence(
      {super.key, this.absenceReason, required this.onDeleteEntry, required this.etatActuel});

  @override
  Widget build(BuildContext context) {
    bool isVacation =
        absenceReason?.toLowerCase().contains('Congés') ?? false;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animation/vacance.json'),
          SizedBox(height: 20),
          if (isVacation)
            Text(
              'En mode détente !',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium,
            )
          else
            const Text(
              'Journée de repos',
              style: TextStyle(
                fontSize: 24.0, // Taille de police augmentée
                fontWeight: FontWeight.bold, // Texte en gras
                color: Colors.blueAccent, // Couleur du texte
                shadows: [
                  Shadow(
                    offset: Offset(2.0, 2.0),
                    blurRadius: 3.0,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          SizedBox(height: 10),
          Text(
            isVacation ? _getRandomVacationPhrase() : 'Prenez soin de vous !',
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            absenceReason!,
            style: Theme
                .of(context)
                .textTheme
                .bodySmall,
          ),
          SizedBox(height: 20),
          PointageRemoveTimesheetDay(
            etatActuel: etatActuel,
            onDeleteEntry: onDeleteEntry,
            isDisabled: false,
          )
        ],
      ),
    );
  }

  String _getRandomVacationPhrase() {
    final phrases = [
      "La plage m'appelle, je réponds présent !",
      "En train de recharger mes batteries... Ne pas déranger !",
      "Si vous me cherchez, je suis quelque part entre le hamac et la piscine.",
      "Aujourd'hui, mon seul objectif est de ne rien faire !",
      "En mission spéciale : tester tous les cocktails du bar de la plage.",
    ];
    return phrases[DateTime
        .now()
        .microsecond % phrases.length];
  }
}
