import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:time_sheet/features/pointage/presentation/widgets/pointage_widget/pointage_card.dart';

class PointageList extends StatelessWidget {
  final List<Map<String, dynamic>> pointages;
  final Function(Map<String, dynamic>) onModifier;

  const PointageList({
    super.key,
    required this.pointages,
    required this.onModifier,
  });

  @override
  Widget build(BuildContext context) {
    // Contenu de la liste (préserve exactement le comportement original)
    return _buildListContent();
  }

  /// Construit le contenu de la liste (préserve exactement le comportement original)
  Widget _buildListContent() {
    if (pointages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pointages.length,
      itemBuilder: (context, index) {
        final pointage = pointages[index];
        return PointageCard(
          type: pointage['type'],
          heure: pointage['heure'],
          onModifier: () =>
              onModifier(pointage), // Préserve exactement le même callback
        )
            .animate(delay: Duration(milliseconds: 100 * index))
            .fadeIn(duration: 500.ms, curve: Curves.easeOutQuad)
            .slideX(
                begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad)
            .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutQuad);
      },
    );
  }

  /// Construit l'état vide quand il n'y a pas de pointages
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xFFE1E8ED),
          width: 1.0,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 48.0,
            color: Color(0xFF95A5A6),
          ),
          SizedBox(height: 16.0),
          Text(
            'Aucun pointage aujourd\'hui',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7F8C8D),
            ),
          ),
          SizedBox(height: 4.0),
          Text(
            'Vos pointages apparaîtront ici une fois que vous aurez commencé votre journée.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7F8C8D),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
