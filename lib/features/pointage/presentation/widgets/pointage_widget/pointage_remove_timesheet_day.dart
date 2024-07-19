import 'package:flutter/material.dart';

class PointageRemoveTimesheetDay extends StatelessWidget {
  final String etatActuel;
  final VoidCallback onDeleteEntry;
  final bool isDisabled;

  const PointageRemoveTimesheetDay({
    super.key,
    required this.etatActuel,
    required this.onDeleteEntry, required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 40,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onDeleteEntry,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          disabledIconColor: Colors.grey,
        ),
        child: const Text(
          'Supprimer la journée',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
