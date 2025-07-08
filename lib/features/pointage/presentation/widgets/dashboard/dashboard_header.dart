import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayName = DateFormat('EEEE', 'fr_FR').format(now);
    final dayNumber = DateFormat('dd').format(now);
    final monthYear = DateFormat('MMMM yyyy', 'fr_FR').format(now);
    
    // Salutation selon l'heure
    final hour = now.hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Bonjour';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Bonsoir';
      greetingIcon = Icons.brightness_3;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade400,
            Colors.teal.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Colonne principale avec texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salutation avec icône
                Row(
                  children: [
                    Icon(
                      greetingIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Date complète
                Text(
                  '$dayName $dayNumber $monthYear',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                // Message contextuel
                Text(
                  'Voici un aperçu de vos activités',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Icône décorative
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}