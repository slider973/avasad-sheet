import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/validation_list_page.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_list/validation_list_bloc.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_menu/validation_menu_bloc.dart';
import 'package:time_sheet/features/validation/presentation/pages/create_validation_page.dart';
import 'package:time_sheet/services/injection_container.dart' as di;

/// Page de menu pour les validations
class ValidationMenuPage extends StatelessWidget {
  const ValidationMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          di.getIt<ValidationMenuBloc>()..add(CheckValidationMenuRole()),
      child: const _ValidationMenuView(),
    );
  }
}

class _ValidationMenuView extends StatelessWidget {
  const _ValidationMenuView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ValidationMenuBloc, ValidationMenuState>(
      builder: (context, state) {
        if (state is ValidationMenuLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final isManager =
            state is ValidationMenuLoaded && state.isManager;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Validation des Timesheets'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte d'information sur le rôle
                Card(
                  color: isManager ? Colors.blue.shade50 : Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isManager ? Icons.manage_accounts : Icons.person,
                              size: 32,
                              color: isManager ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isManager ? 'Manager' : 'Employé',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isManager
                              ? 'Vous pouvez valider les timesheets et gérer vos propres demandes'
                              : 'Vous pouvez créer et suivre vos demandes de validation',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Options employé (toujours visibles)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_circle_outline,
                        color: Colors.green),
                    title: const Text('Créer une demande de validation'),
                    subtitle:
                        const Text('Soumettre une timesheet pour validation'),
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
                              ..add(LoadValidations(
                                  viewType: ValidationViewType.employee)),
                            child: const ValidationListPage(
                                viewType: ValidationViewType.employee),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Options manager (visibles uniquement pour les managers)
                if (isManager) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Gestion d\'équipe',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.assignment, color: Colors.blue),
                      title: const Text('Validations en attente'),
                      subtitle:
                          const Text('Valider les timesheets des employés'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BlocProvider(
                              create: (context) =>
                                  di.getIt<ValidationListBloc>()
                                    ..add(LoadValidations(
                                        viewType: ValidationViewType.manager)),
                              child: const ValidationListPage(
                                  viewType: ValidationViewType.manager),
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
                            const Icon(Icons.info_outline,
                                size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Informations système',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les validations sont gérées via Supabase',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                        Text(
                          'Les PDFs sont stockés sur Supabase Storage',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
      },
    );
  }
}
