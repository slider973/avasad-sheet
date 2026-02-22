import 'package:flutter/material.dart';

/// Widget pour configurer le mode de calcul des heures supplémentaires
class OvertimeCalculationModeWidget extends StatelessWidget {
  final OvertimeCalculationMode currentMode;
  final ValueChanged<OvertimeCalculationMode> onModeChanged;

  const OvertimeCalculationModeWidget({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Calcul des heures supplémentaires',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'Mode de calcul mensuel avec compensation des déficits',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),

            Text(
              'Les jours avec moins d\'heures sont compensés par les jours avec plus d\'heures. '
              'Seuil standard : 8h18 par jour.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Exemple de calcul
            _buildCalculationExample(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationExample(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Exemple de calcul',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            'Semaine avec : Lundi 6h, Mardi 10h30',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),

          // Calcul mensuel avec compensation
          _buildExampleRow(
            context,
            'Calcul avec compensation :',
            'Total: 16h30, Attendu: 16h36 = 0h sup (déficit de 6min compensé)',
            Colors.green.shade700,
          ),

          const SizedBox(height: 8),

          Text(
            'Les déficits d\'heures sont automatiquement compensés par les excès d\'autres jours du mois.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleRow(
    BuildContext context,
    String label,
    String calculation,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
              ),
              Text(
                calculation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Énumération pour les modes de calcul des heures supplémentaires
enum OvertimeCalculationMode {
  /// Calcul journalier (ancien comportement)
  daily,

  /// Calcul mensuel avec compensation des déficits (système par défaut)
  monthlyWithCompensation,
}

extension OvertimeCalculationModeExtension on OvertimeCalculationMode {
  String get displayName {
    switch (this) {
      case OvertimeCalculationMode.daily:
        return 'Calcul journalier';
      case OvertimeCalculationMode.monthlyWithCompensation:
        return 'Calcul mensuel avec compensation';
    }
  }

  String get description {
    switch (this) {
      case OvertimeCalculationMode.daily:
        return 'Heures supplémentaires calculées chaque jour individuellement';
      case OvertimeCalculationMode.monthlyWithCompensation:
        return 'Déficits d\'heures compensés par les excès du mois (8h18/jour)';
    }
  }

  IconData get icon {
    switch (this) {
      case OvertimeCalculationMode.daily:
        return Icons.today;
      case OvertimeCalculationMode.monthlyWithCompensation:
        return Icons.calendar_month;
    }
  }
}
