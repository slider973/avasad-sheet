import 'package:flutter/material.dart';
import 'pointage_design_system.dart';

/// Floating Action Button moderne pour les actions de pointage
/// Suit les Material Design guidelines avec animations fluides
class PointageFAB extends StatelessWidget {
  final String etatActuel;
  final VoidCallback onPressed;
  final bool isLoading;

  const PointageFAB({
    super.key,
    required this.etatActuel,
    required this.onPressed,
    this.isLoading = false,
  });

  Color _getButtonColor() {
    switch (etatActuel) {
      case 'Non commencé':
        return Colors.teal;
      case 'Entrée':
        return const Color(0xFF365E32);
      case 'Pause':
        return const Color(0xFF81A263);
      default:
        return const Color(0xFFFD9B63);
    }
  }

  IconData _getButtonIcon() {
    switch (etatActuel) {
      case 'Non commencé':
        return Icons.play_arrow;
      case 'Entrée':
        return Icons.pause;
      case 'Pause':
        return Icons.play_arrow;
      default:
        return Icons.stop;
    }
  }

  String _getButtonLabel() {
    switch (etatActuel) {
      case 'Non commencé':
        return 'Commencer';
      case 'Entrée':
        return 'Pause';
      case 'Pause':
        return 'Reprise';
      default:
        return 'Terminer';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher le FAB si l'état est 'Sortie'
    if (etatActuel == 'Sortie') {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: _getButtonColor(),
      foregroundColor: Colors.white,
      elevation: 8,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              _getButtonIcon(),
              size: 24,
            ),
      label: Text(
        _getButtonLabel(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Version compacte du FAB pour les espaces restreints
class PointageFABCompact extends StatelessWidget {
  final String etatActuel;
  final VoidCallback onPressed;
  final bool isLoading;

  const PointageFABCompact({
    super.key,
    required this.etatActuel,
    required this.onPressed,
    this.isLoading = false,
  });

  Color _getButtonColor() {
    switch (etatActuel) {
      case 'Non commencé':
        return Colors.teal;
      case 'Entrée':
        return const Color(0xFF365E32);
      case 'Pause':
        return const Color(0xFF81A263);
      default:
        return const Color(0xFFFD9B63);
    }
  }

  IconData _getButtonIcon() {
    switch (etatActuel) {
      case 'Non commencé':
        return Icons.play_arrow;
      case 'Entrée':
        return Icons.pause;
      case 'Pause':
        return Icons.play_arrow;
      default:
        return Icons.stop;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher le FAB si l'état est 'Sortie'
    if (etatActuel == 'Sortie') {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: isLoading ? null : onPressed,
      backgroundColor: _getButtonColor(),
      foregroundColor: Colors.white,
      elevation: 8,
      highlightElevation: 12,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              _getButtonIcon(),
              size: 28,
            ),
    );
  }
}

/// Widget pour afficher le message de félicitations quand l'état est 'Sortie'
class PointageCompletionMessage extends StatelessWidget {
  const PointageCompletionMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
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
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Félicitations !',
            style: PointageTextStyles.cardValue.copyWith(
              color: PointageColors.success,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Votre journée de travail est terminée.',
            style: PointageTextStyles.cardLabel.copyWith(
              color: PointageColors.success.withValues(alpha: 0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
