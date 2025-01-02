import 'package:flutter/material.dart';
import '../../widgets/monthly_stats_widget/monthly_stats_widget.dart';

class StatistiquePage extends StatelessWidget {
  const StatistiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Ajout du bouton de retour
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Statistiques'),
        // Optionnel : si vous voulez que l'AppBar soit transparent/sans élévation
        elevation: 0,
      ),
      body:  const Center(
        child: MonthlyStatsWidget(),
      ),
    );
  }
}