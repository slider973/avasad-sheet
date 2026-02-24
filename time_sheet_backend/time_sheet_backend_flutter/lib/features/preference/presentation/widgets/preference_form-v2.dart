import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/supabase/supabase_service.dart';
import '../../../pointage/presentation/pages/pdf/pages/signature_page.dart';
import '../../../pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../../../pointage/domain/entities/timesheet_generation_config.dart';
import '../../../pointage/presentation/pages/timesheet_generation_config_page.dart';
import '../pages/weekend_settings_page.dart';
import '../pages/reminder_settings_page.dart';
import '../manager/preferences_bloc.dart';

class PreferencesFormV2 extends StatefulWidget {
  const PreferencesFormV2({super.key});

  @override
  _PreferencesFormV2State createState() => _PreferencesFormV2State();
}

class _PreferencesFormV2State extends State<PreferencesFormV2> {
  @override
  void initState() {
    super.initState();
    context.read<PreferencesBloc>().add(LoadPreferences());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text('Paramètres'),
      ),
      body: BlocConsumer<PreferencesBloc, PreferencesState>(
        listener: (context, state) {
          if (state is PreferencesSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Préférences enregistrées')),
            );
          } else if (state is PreferencesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${state.message}')),
            );
          }
        },
        builder: (context, state) {
          if (state is PreferencesLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is PreferencesLoaded) {
            return ListView(
              children: [
                _buildListTile(
                  icon: Icons.person,
                  title: 'Informations personnelles',
                  subtitle: '${state.firstName} ${state.lastName}',
                  onTap: () => _showPersonalInfoDialog(context, state),
                ),
                _buildSignatureTile(state),
                _buildSwitchListTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  value: state.notificationsEnabled,
                  onChanged: (value) {
                    context
                        .read<PreferencesBloc>()
                        .add(ToggleNotifications(value));
                  },
                ),
                _buildSwitchListTile(
                  icon: Icons.work,
                  title: 'Manager de livraison',
                  value: state.isDeliveryManager,
                  onChanged: (value) {
                    context
                        .read<PreferencesBloc>()
                        .add(ToggleDeliveryManager(value));
                  },
                ),
                _buildListTile(
                  icon: Icons.weekend,
                  title: 'Heures supplémentaires',
                  subtitle:
                      'Configuration des heures supplémentaires et weekends',
                  onTap: () => _navigateToWeekendSettings(context),
                ),
                _buildReminderSettingsTile(state),
                _buildListTile(
                  icon: Icons.backup,
                  title: 'Sauvegarde et Restauration',
                  onTap: () => _showBackupRestoreDialog(context),
                ),
                _buildListTile(
                  icon: Icons.access_time,
                  title: 'Génération de Timesheet',
                  subtitle: _isGeneratedThisMonth(state.lastGenerationDate)
                      ? 'Déjà généré ce mois-ci'
                      : 'Générer pour ce mois',
                  onTap: () async {
                    final result =
                        await Navigator.push<TimesheetGenerationConfig>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TimesheetGenerationConfigPage(),
                      ),
                    );

                    if (result != null && mounted) {
                      context
                          .read<TimeSheetBloc>()
                          .add(GenerateMonthlyTimesheetEvent(config: result));
                      context
                          .read<PreferencesBloc>()
                          .add(SaveLastGenerationDate(DateTime.now()));
                    }
                  },
                ),
                _buildVersionInfo(state.versionNumber, state.buildNumber),
              ],
            );
          } else {
            return const Center(child: Text('Une erreur s\'est produite'));
          }
        },
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchListTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.teal),
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.teal,
    );
  }

  void _showPersonalInfoDialog(BuildContext context, PreferencesLoaded state) async {
    final firstNameController = TextEditingController(text: state.firstName);
    final lastNameController = TextEditingController(text: state.lastName);

    // Charger les organisations enfants depuis Supabase
    List<Map<String, dynamic>> organizations = [];
    try {
      final response = await SupabaseService.instance.client
          .rpc('list_child_organizations');
      organizations = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur chargement organisations: $e');
    }

    // Pré-sélectionner l'organisation actuelle basée sur le nom
    String? selectedOrgId;
    for (final org in organizations) {
      if (org['name'] == state.company) {
        selectedOrgId = org['id'] as String;
        break;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Informations personnelles'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedOrgId,
                    decoration: const InputDecoration(labelText: 'Entreprise'),
                    isExpanded: true,
                    items: organizations.map((org) {
                      return DropdownMenuItem<String>(
                        value: org['id'] as String,
                        child: Text(org['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedOrgId = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Annuler'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: const Text('Enregistrer'),
                  onPressed: () {
                    String companyName = state.company;
                    if (selectedOrgId != null) {
                      for (final org in organizations) {
                        if (org['id'] == selectedOrgId) {
                          companyName = org['name'] as String;
                          break;
                        }
                      }
                    }
                    this.context.read<PreferencesBloc>().add(SavePreferences(
                          firstName: firstNameController.text,
                          lastName: lastNameController.text,
                          company: companyName,
                          organizationId: selectedOrgId,
                        ));
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToSignatureScreen() async {
    final result = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (context) => SignatureScreen(
          onSigned: (Uint8List signature) {
            context
                .read<PreferencesBloc>()
                .add(SaveSignature(signature: signature));
          },
        ),
      ),
    );
    if (result != null && mounted) {
      context.read<PreferencesBloc>().add(SaveSignature(signature: result));
    }
  }

  void _showBackupRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Synchronisation'),
        content: const Text(
          'Vos données sont automatiquement synchronisées avec le serveur via PowerSync. '
          'Aucune sauvegarde manuelle n\'est nécessaire.',
        ),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  bool _isGeneratedThisMonth(DateTime? lastGenerationDate) {
    if (lastGenerationDate == null) return false;
    final now = DateTime.now();
    return lastGenerationDate.year == now.year &&
        lastGenerationDate.month == now.month;
  }

  Widget _buildSignatureTile(PreferencesLoaded state) {
    bool hasSignature =
        state.signatureBase64 != null || state.signature != null;
    return ListTile(
      leading: Icon(Icons.gesture, color: Colors.teal),
      title: Text('Signature'),
      subtitle: Text(hasSignature ? 'Signature ajoutée' : 'Aucune signature'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSignature)
            IconButton(
              icon: Icon(Icons.visibility, color: Colors.teal),
              onPressed: () => _showSignatureDialog(context, state),
            ),
          Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => _navigateToSignatureScreen(),
    );
  }

  void _showSignatureDialog(BuildContext context, PreferencesLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Votre signature'),
        content: Container(
          width: 300,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: state.signature != null
              ? Image.memory(state.signature!)
              : state.signatureBase64 != null
                  ? Image.memory(base64Decode(state.signatureBase64!))
                  : const Center(child: Text('Aucune signature disponible')),
        ),
        actions: [
          TextButton(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Modifier'),
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToSignatureScreen();
            },
          ),
        ],
      ),
    );
  }

  void _navigateToWeekendSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeekendSettingsPage(),
      ),
    );
  }

  Widget _buildReminderSettingsTile(PreferencesLoaded state) {
    final reminderSettings = state.reminderSettings;
    final isEnabled = reminderSettings?.enabled ?? false;

    String subtitle;
    if (isEnabled) {
      final clockInTime = reminderSettings!.clockInTime;
      final clockOutTime = reminderSettings.clockOutTime;
      subtitle =
          'Actif - ${_formatTime(clockInTime)} à ${_formatTime(clockOutTime)}';
    } else {
      subtitle = 'Rappels désactivés';
    }

    return ListTile(
      leading: Icon(
        isEnabled ? Icons.notifications_active : Icons.notifications_off,
        color: Colors.teal,
      ),
      title: const Text('Rappels de Pointage'),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navigateToReminderSettings(context),
    );
  }

  void _navigateToReminderSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReminderSettingsPage(),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

Widget _buildVersionInfo(String versionNumber, String buildNumber) {
  return ListTile(
    leading: const Icon(Icons.info_outline, color: Colors.teal),
    title: const Text('Version de l\'application'),
    subtitle: Text('Version $versionNumber (Build $buildNumber)'),
  );
}
