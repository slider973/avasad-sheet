import 'package:flutter/material.dart';


class PointageRemoveTimesheetDay extends StatelessWidget {
  final String etatActuel;
  final VoidCallback onDeleteEntry;

  const PointageRemoveTimesheetDay({
    super.key,
    required this.etatActuel, required this.onDeleteEntry,
  });

  @override
  Widget build(BuildContext context) {
    if(etatActuel  != 'Sortie') {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: 320,
      height: 40,
      child: ElevatedButton(
        onPressed: onDeleteEntry,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: const Text(
          'Supprimer la journée',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}