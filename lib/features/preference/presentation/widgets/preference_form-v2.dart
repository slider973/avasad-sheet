import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../pointage/presentation/pages/pdf/pages/signature_page.dart';
import '../../../pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../manager/preferences_bloc.dart';

import '../../../../services/backup.dart';
import '../../../../services/restart_service.dart';

class PreferencesFormV2 extends StatefulWidget {
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
                  onTap: () {
                    if (!_isGeneratedThisMonth(state.lastGenerationDate)) {
                      context
                          .read<TimeSheetBloc>()
                          .add(const GenerateMonthlyTimesheetEvent());
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
      activeColor: Colors.teal,
    );
  }

  void _showPersonalInfoDialog(BuildContext context, PreferencesLoaded state) {
    final _firstNameController = TextEditingController(text: state.firstName);
    final _lastNameController = TextEditingController(text: state.lastName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informations personnelles'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Prénom'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Nom'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Enregistrer'),
            onPressed: () {
              context.read<PreferencesBloc>().add(SavePreferences(
                    firstName: _firstNameController.text,
                    lastName: _lastNameController.text,
                  ));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
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
    if (result != null) {
      context.read<PreferencesBloc>().add(SaveSignature(signature: result));
    }
  }

  void _showBackupRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarde et Restauration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              child: const Text('Sauvegarder'),
              onPressed: () => _performBackup(),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              child: const Text('Restaurer'),
              onPressed: () => _performRestore(),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Fermer'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _performBackup() async {
    final backupService = GetIt.instance<BackupService>();
    try {
      final backupPath = await backupService.backupDatabase();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sauvegarde réussie : $backupPath')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la sauvegarde : ${e.toString()}')),
      );
    }
  }

  void _performRestore() async {
    final backupService = GetIt.instance<BackupService>();
    try {
      final importSuccess = await backupService.importDatabase();
      if (importSuccess) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Restauration réussie'),
              content: const Text(
                  'La restauration a réussi. L\'application doit être redémarrée pour appliquer les changements.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Redémarrer'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await RestartService.restartApp();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erreur lors de la restauration : ${e.toString()}')),
      );
    }
  }

  bool _isGeneratedThisMonth(DateTime? lastGenerationDate) {
    if (lastGenerationDate == null) return false;
    final now = DateTime.now();
    return lastGenerationDate.year == now.year &&
        lastGenerationDate.month == now.month;
  }

  Widget _buildSignatureTile(PreferencesLoaded state) {
    bool hasSignature = state.signatureBase64 != null || state.signature != null;
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
  }}
Widget _buildVersionInfo(String versionNumber, String buildNumber) {
  return ListTile(
    leading: const Icon(Icons.info_outline, color: Colors.teal),
    title: const Text('Version de l\'application'),
    subtitle: Text('Version $versionNumber (Build $buildNumber)'),
  );
}