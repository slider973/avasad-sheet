import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/core/services/storage/storage_service.dart';
import 'package:time_sheet/core/services/supabase/supabase_service.dart';
import 'package:time_sheet/features/auth/domain/entities/app_user.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/features/preference/presentation/widgets/signature_pad_widget.dart';
import 'dart:typed_data';

class OnboardingPage extends StatefulWidget {
  final AppUser user;

  const OnboardingPage({super.key, required this.user});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Uint8List? _signatureData;
  bool _signatureLoading = false;
  bool _signatureSaving = false;
  bool _signatureSaved = false;
  String? _signatureSaveMessage;
  bool _showSignaturePad = false;
  int _currentPage = 0;
  List<Map<String, dynamic>> _organizations = [];
  String? _selectedOrgId;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
    _loadExistingSignature();
  }

  Future<void> _loadExistingSignature() async {
    if (widget.user.signatureUrl == null) return;
    setState(() => _signatureLoading = true);
    try {
      final bytes = await StorageService().downloadSignature();
      if (mounted && bytes != null) {
        setState(() {
          _signatureData = bytes;
          _signatureSaved = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement signature existante: $e');
    } finally {
      if (mounted) setState(() => _signatureLoading = false);
    }
  }

  Future<void> _loadOrganizations() async {
    try {
      final response = await SupabaseService.instance.client
          .rpc('list_child_organizations');
      if (mounted) {
        setState(() {
          _organizations = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement organisations: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _formKey.currentState!.validate()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentPage == 1 && _signatureSaved) {
      _saveAndFinish();
    }
  }

  Future<void> _saveSignature(Uint8List signature) async {
    setState(() {
      _signatureData = signature;
      _signatureSaving = true;
      _signatureSaveMessage = null;
    });
    try {
      await StorageService().uploadSignature(signature);
      if (mounted) {
        setState(() {
          _signatureSaved = true;
          _signatureSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature enregistrée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _signatureSaving = false;
          _signatureData = null;
          _signatureSaveMessage = 'Erreur lors de l\'enregistrement. Veuillez réessayer.';
        });
      }
    }
  }

  void _saveAndFinish() {
    String companyName = '';
    if (_selectedOrgId != null) {
      for (final org in _organizations) {
        if (org['id'] == _selectedOrgId) {
          companyName = org['name'] as String;
          break;
        }
      }
    }
    // Sauvegarder les données dans les préférences
    context.read<PreferencesBloc>().add(
      SaveUserInfoEvent(
        firstName: widget.user.firstName,
        lastName: widget.user.lastName,
        company: companyName,
        organizationId: _selectedOrgId,
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
            Text(
              'Bienvenue ${widget.user.firstName} !',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Veuillez sélectionner votre entreprise pour continuer.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            DropdownButtonFormField<String>(
              initialValue: _selectedOrgId,
              decoration: const InputDecoration(
                labelText: 'Entreprise',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              items: _organizations.map((org) {
                return DropdownMenuItem<String>(
                  value: org['id'] as String,
                  child: Text(org['name'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOrgId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Veuillez sélectionner votre entreprise';
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
          Text(
            _signatureSaved
                ? 'Votre signature a été récupérée. Vous pouvez la modifier ou continuer.'
                : 'Veuillez signer ci-dessous. Cette signature sera utilisée pour vos feuilles de temps.',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 40),
          if (_signatureLoading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_signatureSaved && !_showSignaturePad)
            Column(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: Image.memory(_signatureData!, fit: BoxFit.contain),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showSignaturePad = true;
                      _signatureData = null;
                      _signatureSaved = false;
                      _signatureSaveMessage = null;
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier la signature'),
                ),
              ],
            )
          else if (_signatureSaving)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SignaturePadWidget(
                onSignatureComplete: _saveSignature,
              ),
            ),
            if (_signatureSaveMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _signatureSaveMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ),
          ],
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
            onPressed: (_currentPage == 1 && !_signatureSaved) ? null : _nextPage,
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