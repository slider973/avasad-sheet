import 'package:flutter/material.dart';

import 'package:time_sheet/config/theme.dart';
import 'package:time_sheet/features/geofencing/domain/entities/geofence_zone.dart';

/// Carte réutilisable affichant une zone surveillée (travail ou domicile)
/// et ses actions : définition depuis la position courante, rayon, suppression.
class ZoneCard extends StatelessWidget {
  /// Titre de la section (« Lieu de travail », « Domicile »).
  final String title;

  /// Phrase d'explication affichée sous le titre.
  final String? description;

  /// Icône illustrant la zone.
  final IconData icon;

  /// Zone définie, ou null si l'utilisateur ne l'a pas encore réglée.
  final GeofenceZone? zone;

  /// Désactive toutes les interactions (interrupteur principal sur OFF).
  final bool enabled;

  /// Vrai pendant l'acquisition de la position GPS.
  final bool isLocating;

  final VoidCallback onUseCurrentPosition;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onRemove;

  const ZoneCard({
    super.key,
    required this.title,
    required this.icon,
    required this.zone,
    required this.enabled,
    required this.isLocating,
    required this.onUseCurrentPosition,
    required this.onRadiusChanged,
    required this.onRemove,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentZone = zone;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: TimeSheetTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (currentZone != null)
                  IconButton(
                    tooltip: 'Supprimer cette zone',
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    onPressed: enabled ? onRemove : null,
                  ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: TimeSheetTheme.grey),
              ),
            ],
            const SizedBox(height: 12),
            if (currentZone == null)
              Text(
                'Aucune zone définie.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: TimeSheetTheme.grey),
              )
            else ...[
              Text(
                currentZone.label.isEmpty ? title : currentZone.label,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 2),
              Text(
                'Latitude ${currentZone.latitude.toStringAsFixed(5)} · '
                'Longitude ${currentZone.longitude.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: TimeSheetTheme.grey),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: (enabled && !isLocating) ? onUseCurrentPosition : null,
                icon: isLocating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(
                  isLocating
                      ? 'Localisation en cours…'
                      : 'Utiliser ma position actuelle',
                ),
              ),
            ),
            if (currentZone != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rayon de détection',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${currentZone.radiusMeters.round()} m',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: currentZone.radiusMeters.clamp(50, 500).toDouble(),
                min: 50,
                max: 500,
                divisions: 45,
                label: '${currentZone.radiusMeters.round()} m',
                onChanged: enabled ? onRadiusChanged : null,
              ),
              Text(
                'Un rayon plus large déclenche plus tôt mais moins précisément.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: TimeSheetTheme.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
