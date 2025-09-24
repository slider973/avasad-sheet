import 'package:flutter/material.dart';
import 'pointage_timer.dart';

/// Demo page to showcase the visual improvements to PointageTimer
class PointageTimerDemo extends StatelessWidget {
  const PointageTimerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PointageTimer Visual Improvements'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visual Improvements Demonstration',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E50),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The PointageTimer now features:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('• Modern container with shadow and white background'),
            const Text('• Improved typography with PointageTimerContent'),
            const Text(
                '• Preserved TimerPainter with existing colors (teal, yellow, orange)'),
            const Text('• All touch interactions maintained'),
            const Text('• Enhanced visual hierarchy'),
            const SizedBox(height: 32),

            // Demo different states
            _buildStateDemo('Non commencé', 'Non commencé', null, []),
            const SizedBox(height: 24),

            _buildStateDemo(
              'Entrée en cours',
              'Entrée',
              DateTime.now().subtract(const Duration(hours: 2)),
              [
                {
                  'type': 'Entrée',
                  'heure': DateTime.now().subtract(const Duration(hours: 2))
                },
              ],
            ),
            const SizedBox(height: 24),

            _buildStateDemo(
              'Pause en cours',
              'Pause',
              DateTime.now().subtract(const Duration(hours: 1)),
              [
                {
                  'type': 'Entrée',
                  'heure': DateTime.now().subtract(const Duration(hours: 3))
                },
                {
                  'type': 'Début pause',
                  'heure': DateTime.now().subtract(const Duration(hours: 1))
                },
              ],
            ),
            const SizedBox(height: 24),

            _buildStateDemo(
              'Journée terminée',
              'Sortie',
              DateTime.now(),
              [
                {
                  'type': 'Entrée',
                  'heure': DateTime.now().subtract(const Duration(hours: 8))
                },
                {
                  'type': 'Début pause',
                  'heure': DateTime.now().subtract(const Duration(hours: 4))
                },
                {
                  'type': 'Fin pause',
                  'heure': DateTime.now().subtract(const Duration(hours: 3))
                },
                {'type': 'Fin de journée', 'heure': DateTime.now()},
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateDemo(
    String title,
    String etat,
    DateTime? dernierPointage,
    List<Map<String, dynamic>> pointages,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3E50),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: PointageTimer(
            etatActuel: etat,
            dernierPointage: dernierPointage,
            progression: 0.5,
            pointages: pointages,
          ),
        ),
      ],
    );
  }
}
