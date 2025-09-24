import 'package:flutter/material.dart';
import 'modern_pointage_button.dart';
import 'pointage_design_system.dart';

class PointageRemoveTimesheetDay extends StatelessWidget {
  final String etatActuel;
  final VoidCallback onDeleteEntry;
  final bool isDisabled;

  const PointageRemoveTimesheetDay({
    super.key,
    required this.etatActuel,
    required this.onDeleteEntry,
    required this.isDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return ModernPointageButton.destructive(
      text: 'Supprimer la journée',
      onPressed: isDisabled ? null : onDeleteEntry,
      icon: Icons.delete_outline,
    );
  }
}
