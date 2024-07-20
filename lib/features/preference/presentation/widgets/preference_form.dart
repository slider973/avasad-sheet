import 'dart:convert';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isAlreadyGenerateForThisMonth = false;
  Uint8List? _signature;

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
        title: const Text('Réglages',
            style: TextStyle(color: Colors.white, fontSize: 18)),
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
              // Ajoutez cette vérification
              _isAlreadyGenerateForThisMonth = _isGeneratedThisMonth(state.lastGenerationDate);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildForm(context),
              );
            } else {
              return const Center(child: Text('Une erreur s\'est produite'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: const Text(
            'Informations personnelles',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        _buildTextField(_firstNameController, 'Prénom'),
        _buildTextField(_lastNameController, 'Nom'),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          child: const Text(
            'Signature',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        _buildSignatureSection(),
        const SizedBox(height: 30),
        Center(
          child: Column(children: [
            _buildButton(
                'Ajouter/Modifier la signature', _navigateToSignatureScreen,
                isPrimary: false),
            const SizedBox(height: 10),
            _buildButton('Enregistrer les informations', _savePreferences),
            const SizedBox(height: 10),
            _buildButton('Générer le timesheet du mois', () {
              context
                  .read<TimeSheetBloc>()
                  .add(const GenerateMonthlyTimesheetEvent());
              context.read<PreferencesBloc>().add(SaveLastGenerationDate(DateTime.now()));
            }, isPrimary: false , disabled: _isAlreadyGenerateForThisMonth),
          ]),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextField(
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        if (_signature != null)
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.memory(_signature!, fit: BoxFit.contain),
            ),
          )
        else
          Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(child: Text('Aucune signature')),
          ),
      ],
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed,
      {disabled = false, bool isPrimary = true}) {
    return SizedBox(
      width: 340,
      height: 40,
      child: ElevatedButton(
        onPressed: disabled ? null :  onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.orange : Colors.teal,
          foregroundColor: isPrimary ? Colors.white : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 0,
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  // Ajoutez cette méthode pour vérifier si le timesheet a été généré ce mois-ci
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
            context
                .read<PreferencesBloc>()
                .add(SaveSignature(signature: signature));
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
    if (_firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty) {
      context.read<PreferencesBloc>().add(SavePreferences(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
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
}
