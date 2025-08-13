import 'package:flutter/material.dart';
import '../../widgets/monthly_stats_widget/monthly_stats_widget.dart';
import '../../../../bottom_nav_tab/presentation/pages/app_drawer.dart';

class StatistiquePage extends StatelessWidget {
  const StatistiquePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: const AppDrawer(),
      body:  const Center(
        child: MonthlyStatsWidget(),
      ),
    );
  }
}