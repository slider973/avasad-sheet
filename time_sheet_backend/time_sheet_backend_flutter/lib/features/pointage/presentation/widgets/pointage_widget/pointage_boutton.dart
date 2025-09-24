import 'package:flutter/material.dart';
import 'modern_pointage_button.dart';
import 'pointage_design_system.dart';

class PointageButton extends StatelessWidget {
  final String etatActuel;
  final VoidCallback onPressed;

  const PointageButton({
    super.key,
    required this.etatActuel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (etatActuel == 'Sortie') {
      return _construireMessageFelicitations();
    }

    return _buildModernButton();
  }

  Widget _buildModernButton() {
    switch (etatActuel) {
      case 'Non commencé':
        return ModernPointageButton.entry(
          onPressed: onPressed,
        );
      case 'Entrée':
        return ModernPointageButton.pause(
          onPressed: onPressed,
        );
      case 'Pause':
        return ModernPointageButton.resume(
          onPressed: onPressed,
        );
      default:
        return ModernPointageButton(
          text: 'Stop',
          onPressed: onPressed,
          style: PointageButtonStyle.exit,
          icon: Icons.stop,
        );
    }
  }

  Widget _construireMessageFelicitations() {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PointageColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PointageColors.success.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: PointageColors.success.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: PointageColors.success,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Félicitations !',
            style: PointageTextStyles.cardValue.copyWith(
              color: PointageColors.success,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Votre journée de travail est terminée.',
            style: PointageTextStyles.cardLabel.copyWith(
              color: PointageColors.success.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
