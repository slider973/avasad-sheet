import 'package:flutter/material.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_boutton.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_list.dart';

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
  final Function(DateTime, DateTime, String, String) onSignalerAbsencePeriode;

  const PointageLayout({
    Key? key,
    required this.etatActuel,
    required this.dernierPointage,
    required this.progression,
    required this.pointages,
    required this.onActionPointage,
    required this.onModifierPointage,
    required this.selectedDate,
    required this.onSignalerAbsencePeriode,
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
          // ElevatedButton(
          //   onPressed: () => _showAbsencePeriodeDialog(context),
          //   child: const Text('Signaler une absence'),
          // ),
          const SizedBox(height: 20),
          PointageList(
            pointages: pointages,
            onModifier: onModifierPointage,
          ),
        ],
      ),
    );
  }
  void _showAbsencePeriodeDialog(BuildContext context) {
    DateTime dateDebut = DateTime.now();
    DateTime dateFin = DateTime.now();
    String type = 'Vacances';
    String raison = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Signaler une absence'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: type,
                    onChanged: (String? newValue) {
                      setState(() {
                        type = newValue!;
                      });
                    },
                    items: <String>['Vacances', 'Maladie']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          dateDebut = picked.start;
                          dateFin = picked.end;
                        });
                      }
                    },
                    child: const Text('Sélectionner la période'),
                  ),
                  TextField(
                    onChanged: (value) => raison = value,
                    decoration: InputDecoration(hintText: "Motif de l'absence"),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Confirmer'),
                  onPressed: () {
                    onSignalerAbsencePeriode(dateDebut, dateFin, type, raison);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
