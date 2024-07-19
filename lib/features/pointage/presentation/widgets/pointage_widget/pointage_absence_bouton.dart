import 'package:flutter/material.dart';

class PointageAbsenceBouton extends StatelessWidget {
  final Function(DateTime, DateTime, String, String) onSignalerAbsencePeriode;
  final String etatActuel;

  const PointageAbsenceBouton({
    Key? key,
    required this.onSignalerAbsencePeriode,
    required this.etatActuel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (etatActuel == 'Sortie') {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 320,
      height: 40,
      child: ElevatedButton(
        onPressed: () => _showAbsencePeriodeDialog(context),
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
                    items: ['Vacances', 'Maladie']
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
                    child: Text(
                        'Période: ${dateDebut.toString().substring(0, 10)} - ${dateFin.toString().substring(0, 10)}'),
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
