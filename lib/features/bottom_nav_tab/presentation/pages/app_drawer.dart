import 'package:flutter/material.dart';
import '../../../pointage/presentation/pages/statistiques/statistique_page.dart';
import '../../../pointage/presentation/pages/pointage/pointage_page.dart';
import '../../../pointage/presentation/pages/dashboard/dashboard_page.dart';
import '../../../preference/presentation/pages/preference.dart';
import 'bottom_navigation_bar.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header avec un container fixe
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.teal,
                  Colors.teal.shade700,
                ],
              ),
            ),
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.access_time, color: Colors.teal, size: 25),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Planet TimeSheet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Corps du drawer avec ListView
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.home,
                  title: 'Accueil',
                  subtitle: 'Retour à la page principale',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const BottomNavigationBarPage()),
                      (route) => false,
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Statistiques',
                  subtitle: 'Voir les statistiques mensuelles',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const StatistiquePage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.timeline,
                  title: 'Tableau de bord',
                  subtitle: 'Aperçu de vos activités',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage()),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.access_time,
                  title: 'Pointage',
                  subtitle: 'Page de pointage journalier',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PointagePage()),
                    );
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.settings,
                  title: 'Paramètres',
                  subtitle: 'Configurer l\'application',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PreferencesPage()),
                    );
                  },
                ),
              ],
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.teal, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }
}