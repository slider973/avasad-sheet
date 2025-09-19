import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../manager/preferences_bloc.dart';
import '../../data/models/reminder_settings.dart';
import '../widgets/reminder_settings_form.dart';

/// Page for configuring reminder notification settings
class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load current reminder settings when page opens
    context.read<PreferencesBloc>().add(LoadReminderSettings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text('Rappels de Pointage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<PreferencesBloc, PreferencesState>(
        listener: (context, state) {
          if (state is PreferencesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PreferencesLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            );
          } else if (state is PreferencesLoaded) {
            final reminderSettings =
                state.reminderSettings ?? ReminderSettings.defaultSettings;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 16),
                  _buildMainToggleCard(reminderSettings),
                  const SizedBox(height: 16),
                  if (reminderSettings.enabled) ...[
                    ReminderSettingsForm(
                      reminderSettings: reminderSettings,
                      onSettingsChanged: _onSettingsChanged,
                    ),
                  ] else ...[
                    _buildDisabledStateCard(),
                  ],
                ],
              ),
            );
          } else {
            return const Center(
              child: Text(
                  'Une erreur s\'est produite lors du chargement des paramètres'),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.teal, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Rappels de Pointage',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configurez des rappels pour ne jamais oublier de pointer votre temps de travail.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainToggleCard(ReminderSettings reminderSettings) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(
          reminderSettings.enabled
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: Colors.teal,
        ),
        title: const Text('Activer les rappels'),
        subtitle: Text(
          reminderSettings.enabled
              ? 'Les rappels sont activés'
              : 'Les rappels sont désactivés',
        ),
        value: reminderSettings.enabled,
        activeThumbColor: Colors.teal,
        onChanged: (bool value) async {
          if (value) {
            // Check and request notification permissions when enabling
            final hasPermission =
                await _checkAndRequestNotificationPermission();
            if (hasPermission) {
              _toggleReminders(value);
            } else {
              _showPermissionDeniedDialog();
            }
          } else {
            _toggleReminders(value);
          }
        },
      ),
    );
  }

  Widget _buildDisabledStateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.notifications_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Rappels désactivés',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activez les rappels ci-dessus pour configurer vos horaires de pointage.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleReminders(bool enabled) {
    context.read<PreferencesBloc>().add(ToggleReminders(enabled));
  }

  void _onSettingsChanged(ReminderSettings newSettings) {
    context.read<PreferencesBloc>().add(SaveReminderSettings(newSettings));
  }

  /// Check and request notification permission
  Future<bool> _checkAndRequestNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    // If permanently denied, show settings dialog
    if (status.isPermanentlyDenied) {
      _showPermissionSettingsDialog();
      return false;
    }

    return false;
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Autorisation requise'),
        content: const Text(
          'Les notifications doivent être autorisées pour recevoir des rappels de pointage. '
          'Veuillez autoriser les notifications dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications désactivées'),
        content: const Text(
          'Les notifications ont été définitivement désactivées. '
          'Pour activer les rappels, veuillez autoriser les notifications '
          'dans les paramètres de votre appareil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide - Rappels de Pointage'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpItem(
                'Activation',
                'Activez les rappels avec l\'interrupteur principal. L\'autorisation de notification sera demandée.',
              ),
              _buildHelpItem(
                'Horaires',
                'Configurez vos heures de pointage d\'entrée et de sortie selon votre emploi du temps.',
              ),
              _buildHelpItem(
                'Jours actifs',
                'Sélectionnez les jours de la semaine où vous souhaitez recevoir des rappels.',
              ),
              _buildHelpItem(
                'Rappels intelligents',
                'Les rappels ne sont envoyés que si vous n\'êtes pas déjà pointé dans l\'état correspondant.',
              ),
              _buildHelpItem(
                'Répétition',
                'Vous pouvez reporter un rappel jusqu\'à 2 fois avec un intervalle de 15 minutes.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(description),
        ],
      ),
    );
  }
}
