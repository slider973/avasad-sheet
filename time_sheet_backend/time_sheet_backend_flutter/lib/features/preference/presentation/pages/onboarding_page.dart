import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/features/preference/presentation/widgets/signature_pad_widget.dart';
import 'dart:typed_data';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List? _signatureData;
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == 1 && _signatureData != null) {
      _saveAndFinish();
    }
  }

  void _saveAndFinish() {
    // Sauvegarder les données dans les préférences
    context.read<PreferencesBloc>().add(
      SaveUserInfoEvent(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        company: _companyController.text,
        signature: _signatureData,
      ),
    );
    
    // Naviguer vers la page principale
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / 2,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildUserInfoPage(),
                  _buildSignaturePage(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bienvenue !',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Pour commencer, nous avons besoin de quelques informations.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Entreprise',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nom de votre entreprise';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignaturePage() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Signature',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Veuillez signer ci-dessous. Cette signature sera utilisée pour vos feuilles de temps.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SignaturePadWidget(
              onSignatureComplete: (signature) {
                setState(() {
                  _signatureData = signature;
                });
              },
            ),
          ),
          if (_signatureData == null)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'Veuillez signer dans le cadre ci-dessus',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text('Retour'),
            )
          else
            const SizedBox(width: 80),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: Text(_currentPage == 1 ? 'Terminer' : 'Suivant'),
          ),
        ],
      ),
    );
  }
}