import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PointageAbsence extends StatelessWidget {
  final String? absenceReason;

  const PointageAbsence({super.key, this.absenceReason});

  @override
  Widget build(BuildContext context) {
    bool isVacation =
        absenceReason?.toLowerCase().contains('vacances') ?? false;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/animation/vacance.json'),
          SizedBox(height: 20),
          if (isVacation)
            Text(
              'En mode détente !',
              style: Theme.of(context).textTheme.headlineMedium,
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
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          Text(
            absenceReason!,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
    return phrases[DateTime.now().microsecond % phrases.length];
  }
}
