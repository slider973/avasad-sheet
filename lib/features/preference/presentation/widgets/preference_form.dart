import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf/pages/signature_page.dart';

import '../../../pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../manager/preferences_bloc.dart';

class PreferencesForm extends StatefulWidget {
  @override
  _PreferencesFormState createState() => _PreferencesFormState();
}

class _PreferencesFormState extends State<PreferencesForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  Uint8List? _signature;

  @override
  void initState() {
    super.initState();
    context.read<PreferencesBloc>().add(LoadPreferences());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préférences')),
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
            _firstNameController.text = state.firstName;
            _lastNameController.text = state.lastName;
            _signature = state.signature;
            return _buildForm(context);
          } else {
            return const Center(child: Text('Une erreur s\'est produite'));
          }
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
            ),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) => value!.isEmpty ? 'Champ obligatoire' : null,
            ),
            const SizedBox(height: 20),
            _buildGenerateTimesheetButton(),
            const SizedBox(height: 20),
            const Text('Signature:'),
            if (_signature != null)
              Image.memory(_signature!, height: 100)
            else
              const Text('Aucune signature'),
            ElevatedButton(
              onPressed: _navigateToSignatureScreen,
              child: const Text('Ajouter/Modifier la signature'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePreferences,
              child: const Text('Enregistrer les informations'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTimesheetButton() {
    return BlocBuilder<TimeSheetBloc, TimeSheetState>(
      builder: (context, state) {
        if (state is TimeSheetLoading) {
          return const CircularProgressIndicator();
        }
        return ElevatedButton(
          onPressed: state is TimeSheetGenerationCompleted
              ? null
              : () {
            context.read<TimeSheetBloc>().add(const GenerateMonthlyTimesheetEvent());
          },
          child: Text(
              state is TimeSheetGenerationCompleted
                  ? 'Génération terminée'
                  : 'Générer le timesheet du mois'
          ),
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
          )),
    );
    if (result != null) {
      setState(() {
        _signature = result;
      });
    }
  }

  void _savePreferences() {
    if (_formKey.currentState!.validate()) {
      context.read<PreferencesBloc>().add(SavePreferences(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      ));
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }
}