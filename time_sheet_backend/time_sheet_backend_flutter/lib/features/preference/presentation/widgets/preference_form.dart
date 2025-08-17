import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/signature_page.dart';
import '../../../../services/restart_service.dart';
import '../../../pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

import '../../../../services/backup.dart';
import '../manager/preferences_bloc.dart';

class PreferencesForm extends StatefulWidget {
  const PreferencesForm({super.key});

  @override
  _PreferencesFormState createState() => _PreferencesFormState();
}

class _PreferencesFormState extends State<PreferencesForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isAlreadyGenerateForThisMonth = false;
  Uint8List? _signature;
  bool _notificationsEnabled = true;
  bool _isDeliveryManager = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = '';
    _lastNameController.text = '';
    context.read<PreferencesBloc>().add(LoadPreferences());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text('Réglages', style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: BlocConsumer<PreferencesBloc, PreferencesState>(
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
              _firstNameController.text = state.firstName;
              _lastNameController.text = state.lastName;
              _signature = state.signature ?? base64Decode(state.signatureBase64 ?? '');
              _isAlreadyGenerateForThisMonth = _isGeneratedThisMonth(state.lastGenerationDate);
              _notificationsEnabled = state.notificationsEnabled;
              _isDeliveryManager = state.isDeliveryManager;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPersonalInfoCard(),
                    const SizedBox(height: 16),
                    _buildSignatureCard(),
                    const SizedBox(height: 16),
                    _buildNotificationsCard(),
                    const SizedBox(height: 16),
                    _buildDeliveryManagerCard(),
                    const SizedBox(height: 16),
                    _buildBackupRestoreCard(),
                    const SizedBox(height: 16),
                    _buildGenereLeTimeSheetDuMois()
                  ],
                ),
              );
            } else {
              return const Center(child: Text('Une erreur s\'est produite'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations personnelles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            _buildTextField(_firstNameController, 'Prénom'),
            const SizedBox(height: 12),
            _buildTextField(_lastNameController, 'Nom'),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Signature',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            _buildSignatureSection(),
            const SizedBox(height: 16),
            _buildButton('Ajouter/Modifier la signature', _navigateToSignatureScreen, isPrimary: false),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildButton('Enregistrer les informations', _savePreferences),
      ],
    );
  }

  Widget _buildGenereLeTimeSheetDuMois() {
    return Column(
      children: [
        _buildButton('Générer les heures de timesheet pour le mois', () {
          context.read<TimeSheetBloc>().add(const GenerateMonthlyTimesheetEvent());
          context.read<PreferencesBloc>().add(SaveLastGenerationDate(DateTime.now()));
        }, isPrimary: false, disabled: _isAlreadyGenerateForThisMonth),
      ],
    );
  }

  Widget _buildNotificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activer les notifications'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                context.read<PreferencesBloc>().add(ToggleNotifications(value));
              },
              activeThumbColor: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryManagerCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manager de livraison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activer le manager de livraison'),
              value: _isDeliveryManager,
              onChanged: (bool value) {
                setState(() {
                  _isDeliveryManager = value;
                });
                context.read<PreferencesBloc>().add(ToggleDeliveryManager(value));
              },
              activeThumbColor: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(15),
      ),
      child: _signature != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(_signature!, fit: BoxFit.contain),
            )
          : const Center(child: Text('Aucune signature')),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {bool disabled = false, bool isPrimary = true}) {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: isPrimary ? Colors.orange : Colors.teal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  bool _isGeneratedThisMonth(DateTime? lastGenerationDate) {
    if (lastGenerationDate == null) return false;
    final now = DateTime.now();
    return lastGenerationDate.year == now.year && lastGenerationDate.month == now.month;
  }

  void _navigateToSignatureScreen() async {
    final result = await Navigator.push<Uint8List?>(
      context,
      MaterialPageRoute(
        builder: (context) => SignatureScreen(
          onSigned: (Uint8List signature) {
            context.read<PreferencesBloc>().add(SaveSignature(signature: signature));
          },
        ),
      ),
    );
    if (result != null) {
      setState(() {
        _signature = result;
      });
    }
  }

  void _savePreferences() {
    if (_firstNameController.text.isNotEmpty && _lastNameController.text.isNotEmpty) {
      context.read<PreferencesBloc>().add(SavePreferences(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            company: '', // TODO: Add company field to the form
          ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Widget _buildBackupRestoreCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sauvegarde et Restauration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 16),
            _buildButton('Sauvegarder', _performBackup),
            const SizedBox(height: 8),
            _buildButton('Restaurer', _performRestore, isPrimary: false),
          ],
        ),
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
        SnackBar(content: Text('Erreur lors de la sauvegarde : ${e.toString()}')),
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
        SnackBar(content: Text('Erreur lors de la restauration : ${e.toString()}')),
      );
    }
  }
}
