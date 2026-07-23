import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../preference/presentation/manager/preferences_bloc.dart';
import '../../../pointage/presentation/pages/statistiques/statistique_page.dart';
import '../../../preference/presentation/pages/preference.dart';
import '../../../validation/presentation/pages/validation_menu_page.dart';
import '../../../expense/presentation/pages/expense_list_page.dart';
import '../../../manager/presentation/pages/manager_dashboard_page.dart';
import '../../../manager/presentation/bloc/manager_dashboard_bloc.dart';
import '../../../pointage/presentation/pages/debug/debug_database_page.dart';
import 'package:fpdart/fpdart.dart';
import 'package:time_sheet/core/error/failures.dart';
import 'package:time_sheet/core/services/supabase/supabase_service.dart';
import 'package:time_sheet/features/validation/domain/entities/notification.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';
import 'package:time_sheet/features/validation/presentation/pages/notifications_page.dart';
import 'package:time_sheet/services/injection_container.dart' as di;

class AppDrawer extends StatelessWidget {
  final bool isManager;

  const AppDrawer({super.key, this.isManager = false});

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
                // Le drawer ne contient que la navigation SECONDAIRE :
                // Accueil, Tableau de bord et Pointage étaient des doublons
                // de la barre du bas (trois chemins vers le même écran) —
                // retirés pour clarifier la hiérarchie de navigation.
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
                  icon: Icons.receipt_long,
                  title: 'Notes de frais',
                  subtitle: 'Gérer vos dépenses professionnelles',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ExpenseListPage()),
                    );
                  },
                ),
                if (isManager)
                  _buildMenuItem(
                    context,
                    icon: Icons.supervisor_account,
                    title: 'Manager',
                    subtitle: 'Tableau de bord équipe',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (_) => di.getIt<ManagerDashboardBloc>(),
                            child: const ManagerDashboardPage(),
                          ),
                        ),
                      );
                    },
                  ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.verified_user,
                  title: 'Validations',
                  subtitle: 'Gérer les validations de timesheet',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ValidationMenuPage()),
                    );
                  },
                ),
                _buildNotificationsItem(context),
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
                // Outil de debug (réparation BDD) : jamais exposé en
                // production, uniquement en build de développement.
                if (kDebugMode)
                  _buildMenuItem(
                    context,
                    icon: Icons.bug_report,
                    title: 'Debug BDD',
                    subtitle: 'Absences, entrées, réparation',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DebugDatabasePage()),
                      );
                    },
                  ),
              ],
            ),
          ),
          // Déconnexion
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 20),
            ),
            title: const Text(
              'Se déconnecter',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Colors.red,
              ),
            ),
            onTap: () => _showSignOutDialog(context),
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

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            key: const Key('confirmSignOutButton'),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PreferencesBloc>().add(ClearPreferences());
              context.read<AuthBloc>().add(AuthSignOutRequested());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }

  /// Entrée drawer "Notifications" avec badge non-lus (watchUserNotifications).
  Widget _buildNotificationsItem(BuildContext context) {
    final repo = di.getIt<ValidationRepository>();
    final userId = SupabaseService.instance.currentUserId ?? '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.notifications, color: Colors.teal, size: 20),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        'Approbations et rappels',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: StreamBuilder<Either<Failure, List<NotificationEntity>>>(
        stream: repo.watchUserNotifications(userId),
        builder: (context, snapshot) {
          final count = snapshot.data?.fold(
                (_) => 0,
                (list) => list.where((n) => !n.read).length,
              ) ??
              0;
          if (count == 0) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NotificationsPage()),
        );
      },
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