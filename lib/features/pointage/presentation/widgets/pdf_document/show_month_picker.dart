import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../pages/pdf/bloc/pdf_bloc.dart';

void showMonthPicker(BuildContext context) {
  final currentDate = DateTime.now();
  int selectedYear = currentDate.year;
  int? selectedMonth;

  showDialog(
    context: context,
    barrierDismissible: false, // Empêche la fermeture en cliquant à l'extérieur
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Sélectionner un mois pour $selectedYear'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          setState(() {
                            selectedYear--;
                            selectedMonth = null;
                          });
                        },
                      ),
                      Text('$selectedYear', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          setState(() {
                            selectedYear++;
                            selectedMonth = null;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(12, (index) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedMonth == index + 1 ? Colors.teal : null,
                        ),
                        child: Text(DateFormat('MMM').format(DateTime(selectedYear, index + 1))),
                        onPressed: () {
                          setState(() {
                            selectedMonth = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Annuler'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  if (selectedMonth != null) {
                    Navigator.of(context).pop();
                    context.read<PdfBloc>().add(GeneratePdfEvent(selectedMonth!));
                  } else {
                    // Afficher un message d'erreur si aucun mois n'est sélectionné
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un mois')),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    },
  );
}