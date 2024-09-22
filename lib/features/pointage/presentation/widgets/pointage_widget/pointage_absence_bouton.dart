import 'package:flutter/material.dart';

import '../../../../../enum/absence_motif.dart';
import '../../../../../enum/absence_period.dart';

class PointageAbsenceBouton extends StatelessWidget {
  final Function(DateTime, DateTime, String, String, String?) onSignalerAbsencePeriode;
  final String etatActuel;
  final DateTime selectedDate;

   PointageAbsenceBouton({
    super.key,
    required this.onSignalerAbsencePeriode,
    required this.etatActuel,
    required this.selectedDate
  });

  @override
  Widget build(BuildContext context) {
    bool canChangePeriod = selectedDate == selectedDate;
    if (etatActuel == 'Sortie') {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 320,
      height: 40,
      child: ElevatedButton(
        onPressed: () => _showAbsencePeriodeDialog(context, canChangePeriod),
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

  void _showAbsencePeriodeDialog(BuildContext context, bool canChangePeriod) {
    DateTime dateDebut = selectedDate;
    DateTime dateFin = selectedDate;
    AbsenceMotif type = AbsenceMotif.publicHoliday;
    String raison = '';
    AbsencePeriod? periode = AbsencePeriod.fullDay;

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
                  DropdownButton<AbsenceMotif>(
                    value: type,
                    onChanged: (AbsenceMotif? newValue) {
                      setState(() {
                        type = newValue!;
                      });
                    },
                    items: AbsenceMotif.values
                        .map<DropdownMenuItem<AbsenceMotif>>((AbsenceMotif value) {
                      return DropdownMenuItem<AbsenceMotif>(
                        value: value,
                        child: Text(value.value),
                      );
                    }).toList(),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        initialDateRange: DateTimeRange(
                          start: dateDebut,
                          end: dateFin,
                        ),
                        locale: const Locale('fr', 'FR'),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          canChangePeriod = picked.start == picked.end;
                          dateDebut = picked.start;
                          dateFin = picked.end;
                        });
                      }
                    },
                    child: Text(
                        'Période: ${dateDebut.toString().substring(0, 10)} - ${dateFin.toString().substring(0, 10)}'),
                  ),
                  if(canChangePeriod && type != AbsenceMotif.publicHoliday)
                    DropdownButton<AbsencePeriod>(
                      value: periode,
                      onChanged: (AbsencePeriod? newValue) {
                        setState(() {
                          periode = newValue!;
                        });
                      },
                      items: AbsencePeriod.values.map<DropdownMenuItem<AbsencePeriod>>((AbsencePeriod value) {
                        return DropdownMenuItem<AbsencePeriod>(
                          value: value,
                          child: Text(value.value),
                        );
                      }).toList(),
                    ),
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        raison = value;
                      });
                    },
                    decoration:
                    const InputDecoration(hintText: "Motif de l'absence"),
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
                    onSignalerAbsencePeriode(dateDebut, dateFin, type.value, raison, periode?.value);
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