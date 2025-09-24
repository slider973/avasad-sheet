import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PointageCard extends StatelessWidget {
  final String type;
  final DateTime heure;
  final VoidCallback onModifier;

  const PointageCard({
    super.key,
    required this.type,
    required this.heure,
    required this.onModifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onModifier,
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Barre d'accent colorée
                Container(
                  width: 4.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: _getAccentColor(),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(width: 16.0),

                // Icône selon le type de pointage
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: _getAccentColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: _getAccentColor(),
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 16.0),

                // Informations de pointage
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Type de pointage
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4.0),

                      // Heure du pointage
                      Text(
                        DateFormat('HH:mm').format(heure),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bouton de modification (préserve exactement le même comportement)
                IconButton(
                  onPressed: onModifier,
                  icon: const Icon(Icons.edit_outlined),
                  color: const Color(0xFF2D3E50),
                  iconSize: 20.0,
                  style: IconButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF2D3E50).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  tooltip: 'Modifier ce pointage',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Retourne la couleur d'accent selon le type de pointage
  Color _getAccentColor() {
    switch (type.toLowerCase()) {
      case 'entrée':
      case 'entree':
        return Colors.teal;
      case 'pause':
        return const Color(0xFFE7D37F);
      case 'reprise':
        return const Color(0xFFFD9B63);
      case 'sortie':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFF2D3E50);
    }
  }

  /// Retourne l'icône appropriée selon le type de pointage
  IconData _getIcon() {
    switch (type.toLowerCase()) {
      case 'entrée':
      case 'entree':
        return Icons.login;
      case 'pause':
        return Icons.pause_circle_outline;
      case 'reprise':
        return Icons.play_circle_outline;
      case 'sortie':
        return Icons.logout;
      default:
        return Icons.access_time;
    }
  }
}
