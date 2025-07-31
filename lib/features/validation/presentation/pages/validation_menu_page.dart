import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/validation_list_page.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_list/validation_list_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/create_validation_page.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/set_user_preference_use_case.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
import 'package:time_sheet/services/injection_container.dart' as di;
import 'package:time_sheet/core/services/supabase/supabase_service.dart';

/// Page de menu pour les validations
class ValidationMenuPage extends StatefulWidget {
  const ValidationMenuPage({super.key});
  
  @override
  State<ValidationMenuPage> createState() => _ValidationMenuPageState();
}

class _ValidationMenuPageState extends State<ValidationMenuPage> {
  bool _isManager = false;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }
  
  Future<void> _checkUserRole() async {
    try {
      // Utiliser Isar pour récupérer les préférences utilisateur
      final getUserPref = di.getIt<GetUserPreferenceUseCase>();
      
      // Récupérer le statut isDeliveryManager
      final isDeliveryManagerStr = await getUserPref.execute('isDeliveryManager') ?? 'false';
      final isManager = isDeliveryManagerStr == 'true';
      
      setState(() {
        _isManager = isManager;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking user role: $e');
      setState(() {
        _isManager = false;
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validations'),
        backgroundColor: Colors.teal,
        actions: [
          // Bouton temporaire pour tester les rôles
          IconButton(
            icon: Icon(_isManager ? Icons.badge : Icons.person),
            onPressed: () async {
              final newIsManager = !_isManager;
              
              // Utiliser le PreferencesBloc pour gérer le toggle
              // Cela va automatiquement sauvegarder dans Isar ET Supabase
              final preferencesBloc = di.getIt<PreferencesBloc>();
              
              // Vérifier d'abord que les infos sont configurées
              final state = preferencesBloc.state;
              if (state is PreferencesLoaded) {
                if (state.firstName.isEmpty || state.lastName.isEmpty || state.company.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez configurer vos informations dans les paramètres'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                // Déclencher le toggle via le bloc
                preferencesBloc.add(ToggleDeliveryManager(newIsManager));
                
                setState(() {
                  _isManager = newIsManager;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(newIsManager 
                      ? 'Mode Manager activé - Synchronisation avec Supabase...' 
                      : 'Mode Employé activé - Retrait de Supabase...'),
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                // Si les préférences ne sont pas chargées, les charger d'abord
                preferencesBloc.add(LoadPreferences());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chargement des préférences...'),
                  ),
                );
              }
            },
            tooltip: 'Basculer entre Employé/Manager',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Gestion des validations',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Chip(
                        label: Text(_isManager ? 'Manager' : 'Employé'),
                        backgroundColor: _isManager ? Colors.purple.shade100 : Colors.blue.shade100,
                        labelStyle: TextStyle(
                          color: _isManager ? Colors.purple.shade800 : Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isManager
                        ? 'Vous pouvez consulter vos validations et celles de vos collaborateurs'
                        : 'Consultez et gérez vos demandes de validation',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Carte pour les validations de l'employé
                  _buildMenuCard(
                    icon: Icons.assignment_ind,
                    title: 'Mes validations',
                    subtitle: 'Voir toutes mes demandes de validation',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider(
                            create: (context) => di.getIt<ValidationListBloc>(),
                            child: const ValidationListPage(
                              viewType: ValidationViewType.employee,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  if (_isManager) ...[
                    const SizedBox(height: 16),
                    
                    // Carte pour les validations à traiter (manager)
                    _buildMenuCard(
                      icon: Icons.assignment_turned_in,
                      title: 'Validations à traiter',
                      subtitle: 'Gérer les demandes de validation de vos collaborateurs',
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) => di.getIt<ValidationListBloc>(),
                              child: const ValidationListPage(
                                viewType: ValidationViewType.manager,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  
                  const Spacer(),
                  
                  // Bouton de test Supabase (temporaire pour debug)
                  if (_isManager)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.bug_report, color: Colors.orange),
                        title: const Text('Tester la connexion Supabase'),
                        subtitle: const Text('Vérifier l\'enregistrement du manager'),
                        onTap: () async {
                          try {
                            final supabase = SupabaseService.instance.client;
                            
                            // Tester la connexion
                            final response = await supabase
                                .from('managers')
                                .select()
                                .limit(5);
                            
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Test Supabase'),
                                  content: Text('Connexion OK!\n\nManagers trouvés: ${response.length}\n\nDonnées: ${response.toString()}'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Erreur Supabase'),
                                  content: Text('Erreur: ${e.toString()}'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Information sur la connexion
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Une connexion internet est requise pour utiliser les fonctionnalités de validation',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: !_isManager
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateValidationPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle validation'),
              backgroundColor: Colors.teal,
            )
          : null,
    );
  }
  
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _registerAsManager(String company, String firstName, String lastName) async {
    try {
      final supabase = SupabaseService.instance.client;
      final managerId = '${company}_${firstName}_${lastName}'.toLowerCase().replaceAll(' ', '_');
      final email = '${firstName.toLowerCase()}.${lastName.toLowerCase()}@${company.toLowerCase().replaceAll(' ', '_')}.ch';
      
      debugPrint('Tentative d\'enregistrement du manager:');
      debugPrint('  ID: $managerId');
      debugPrint('  Company: $company');
      debugPrint('  Name: $firstName $lastName');
      debugPrint('  Email: $email');
      
      final response = await supabase.from('managers').upsert({
        'id': managerId,
        'company': company,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
      }).select();
      
      debugPrint('Manager enregistré avec succès: $response');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistré comme manager dans Supabase'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'enregistrement du manager: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
  
  Future<void> _unregisterAsManager(String company, String firstName, String lastName) async {
    try {
      final supabase = SupabaseService.instance.client;
      final managerId = '${company}_${firstName}_${lastName}'.toLowerCase().replaceAll(' ', '_');
      
      await supabase.from('managers').delete().eq('id', managerId);
      
      debugPrint('Manager supprimé de Supabase: $managerId');
    } catch (e) {
      debugPrint('Erreur lors de la suppression du manager: $e');
    }
  }
}