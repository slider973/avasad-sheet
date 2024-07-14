import 'package:flutter/material.dart';

class PointageButton extends StatelessWidget {
  final String etatActuel;
  final VoidCallback onPressed;

  const PointageButton({
    Key? key,
    required this.etatActuel,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
   if(etatActuel == 'Sortie') {
      return _construireMessageFelicitations();
    }
   return SizedBox(
     width: 320,
     height: 40,
     child: ElevatedButton(
       onPressed: onPressed,
       style: ElevatedButton.styleFrom(
         backgroundColor: _getButtonColor(etatActuel),
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(15),
         ),
       ),
       child: Text(
         _getButtonText(),
         style: const TextStyle(fontSize: 15),
       ),
     ),
   );
  }

  String _getButtonText() {
    switch (etatActuel) {
      case 'Non commencé':
        return 'Commencer';
      case 'Entrée':
        return 'Pause';
      case 'Pause':
        return 'Reprise';
      case 'Sortie':
        return 'Reset';
      default:
        return 'Stop';
    }
  }

  Color _getButtonColor(String etatActuel) {
    switch (etatActuel) {
      case 'Non commencé':
        return Colors.teal;
      case 'Entrée':
        return const Color(0xFF365E32);
      case 'Pause':
        return const Color(0xFF81A263);
      case 'Sortie':
        return const Color(0xFFE7D37F);
      default:
        return const Color(0xFFFD9B63);
    }
  }
  Widget _construireMessageFelicitations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Text(
        'Félicitations ! Votre journée de travail est terminée.',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}