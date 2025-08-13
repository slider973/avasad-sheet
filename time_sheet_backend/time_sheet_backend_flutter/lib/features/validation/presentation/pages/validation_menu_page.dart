import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/validation_list_page.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_list/validation_list_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/create_validation_page.dart';
import 'package:time_sheet/features/preference/domain/use_cases/get_user_preference_use_case.dart';
import 'package:time_sheet/features/preference/domain/use_cases/set_user_preference_use_case.dart';
import 'package:time_sheet/services/injection_container.dart' as di;

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
  
  Future<void> _toggleManagerRole() async {
    try {
      final setUserPref = di.getIt<SetUserPreferenceUseCase>();
      final getUserPref = di.getIt<GetUserPreferenceUseCase>();
      
      // Récupérer les préférences actuelles
      final firstName = await getUserPref.execute('firstName') ?? '';
      final lastName = await getUserPref.execute('lastName') ?? '';
      final company = await getUserPref.execute('company') ?? '';
      
      // Inverser le statut
      final newStatus = !_isManager;
      await setUserPref.execute('isDeliveryManager', newStatus.toString());
      
      if (mounted) {
        setState(() {
          _isManager = newStatus;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Mode Manager activé - Utilisation de Serverpod' 
                  : 'Mode Employé activé'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling manager role: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Timesheets'),
        actions: [
          // Switch pour basculer entre employé et manager
          Row(
            children: [
              const Text('Manager'),
              Switch(
                value: _isManager,
                onChanged: (value) => _toggleManagerRole(),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carte d'information sur le rôle
            Card(
              color: _isManager ? Colors.blue.shade50 : Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isManager ? Icons.manage_accounts : Icons.person,
                          size: 32,
                          color: _isManager ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isManager ? 'Mode Manager' : 'Mode Employé',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isManager
                          ? 'Vous pouvez valider les timesheets des employés'
                          : 'Vous pouvez créer et suivre vos demandes de validation',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Options disponibles selon le rôle
            if (!_isManager) ...[
              // Options pour les employés
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                  title: const Text('Créer une demande de validation'),
                  subtitle: const Text('Soumettre une timesheet pour validation'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateValidationPage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.orange),
                  title: const Text('Mes demandes de validation'),
                  subtitle: const Text('Voir l\'historique de mes demandes'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => di.getIt<ValidationListBloc>()
                            ..add(LoadValidations(viewType: ValidationViewType.employee)),
                          child: const ValidationListPage(viewType: ValidationViewType.employee),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // Options pour les managers
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.blue),
                  title: const Text('Validations en attente'),
                  subtitle: const Text('Valider les timesheets des employés'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => di.getIt<ValidationListBloc>()
                            ..add(LoadValidations(viewType: ValidationViewType.manager)),
                          child: const ValidationListPage(viewType: ValidationViewType.manager),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            const Spacer(),
            
            // Informations sur le système
            Card(
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Informations système',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Les validations sont gérées via Serverpod',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Les PDFs sont stockés côté serveur',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}