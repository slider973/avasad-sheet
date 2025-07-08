import 'package:flutter/material.dart';
import '../../pages/pointage/pointage_page.dart';
import '../../pages/pdf/pages/pdf_document_page.dart';
import '../../pages/anomaly/anomaly.dart';
import '../../pages/statistiques/statistique_page.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: const Text(
                    'Actions rapides',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions rapides
            Column(
              children: [
                // Aller au pointage
                _buildActionButton(
                  context,
                  'Pointage',
                  'Aller à la page de pointage',
                  Icons.access_time,
                  Colors.teal,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const PointagePage()),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Générer PDF
                _buildActionButton(
                  context,
                  'Générer PDF',
                  'Export du rapport mensuel',
                  Icons.picture_as_pdf,
                  Colors.red,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PdfDocumentPage()),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Voir calendrier
                _buildActionButton(
                  context,
                  'Calendrier',
                  'Vue calendrier des pointages',
                  Icons.calendar_today,
                  Colors.blue,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const StatistiquePage()),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                // Voir anomalies
                _buildActionButton(
                  context,
                  'Anomalies',
                  'Gérer les anomalies',
                  Icons.warning,
                  Colors.orange,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => AnomalyView()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}