import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/validation/presentation/bloc/create_validation/create_validation_bloc.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf_generation_page.dart';
import 'package:time_sheet/services/injection_container.dart' as di;
import 'dart:typed_data';

/// Page de création d'une demande de validation
class CreateValidationPage extends StatefulWidget {
  const CreateValidationPage({super.key});
  
  @override
  State<CreateValidationPage> createState() => _CreateValidationPageState();
}

class _CreateValidationPageState extends State<CreateValidationPage> {
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.getIt<CreateValidationBloc>()..add(const LoadManagers()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Nouvelle demande de validation'),
        ),
        body: BlocConsumer<CreateValidationBloc, CreateValidationState>(
        listener: (context, state) {
          if (state is CreateValidationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demande de validation créée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
          
          if (state is CreateValidationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CreateValidationLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is CreateValidationSubmitting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Envoi en cours...'),
                ],
              ),
            );
          }
          
          if (state is CreateValidationError && !(state is CreateValidationForm)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CreateValidationBloc>().add(const LoadManagers());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }
          
          if (state is CreateValidationForm) {
            return _buildForm(state);
          }
          
          return const SizedBox();
        },
      ),
    ),
  );
  }
  
  Widget _buildForm(CreateValidationForm state) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section Manager
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Manager',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Manager>(
                    value: state.selectedManager,
                    decoration: const InputDecoration(
                      labelText: 'Sélectionner un manager',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.supervisor_account),
                    ),
                    items: state.availableManagers.map((manager) {
                      return DropdownMenuItem(
                        value: manager,
                        child: Text(manager.name ?? manager.email),
                      );
                    }).toList(),
                    onChanged: (manager) {
                      if (manager != null) {
                        context.read<CreateValidationBloc>().add(
                          SelectManager(manager),
                        );
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner un manager';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section Période
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Période',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          'Date de début',
                          state.periodStart,
                          (date) {
                            if (date != null) {
                              context.read<CreateValidationBloc>().add(
                                SelectPeriod(
                                  startDate: date,
                                  endDate: state.periodEnd ?? date,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateField(
                          'Date de fin',
                          state.periodEnd,
                          (date) {
                            if (date != null) {
                              context.read<CreateValidationBloc>().add(
                                SelectPeriod(
                                  startDate: state.periodStart ?? date,
                                  endDate: date,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (state.periodStart != null && state.periodEnd != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _calculateDuration(state.periodStart!, state.periodEnd!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Section PDF
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'Document PDF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (state.pdfBytes == null) ...[
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: state.periodStart != null && state.periodEnd != null
                            ? () => _generatePdf(state)
                            : null,
                        icon: const Icon(Icons.create),
                        label: const Text('Générer le PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    if (state.periodStart == null || state.periodEnd == null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez une période pour générer le PDF',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.pdfFileName ?? 'timesheet.pdf',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Taille: ${_formatFileSize(state.pdfBytes!.length)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: () => _generatePdf(state),
                            tooltip: 'Régénérer',
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Message d'erreur
          if (state.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: state.isValid
                      ? () {
                          if (_formKey.currentState!.validate()) {
                            context.read<CreateValidationBloc>().add(
                              const SubmitValidation(),
                            );
                          }
                        }
                      : null,
                  child: const Text('Envoyer'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          locale: const Locale('fr', 'CH'),
        );
        onChanged(date);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          value != null
              ? DateFormat('dd/MM/yyyy').format(value)
              : 'Sélectionner',
          style: TextStyle(
            color: value != null ? null : Colors.grey,
          ),
        ),
      ),
    );
  }
  
  String _calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start).inDays + 1;
    if (duration == 1) {
      return '1 jour';
    } else if (duration < 7) {
      return '$duration jours';
    } else {
      final weeks = duration ~/ 7;
      final days = duration % 7;
      if (days == 0) {
        return '$weeks semaine${weeks > 1 ? 's' : ''}';
      } else {
        return '$weeks semaine${weeks > 1 ? 's' : ''} et $days jour${days > 1 ? 's' : ''}';
      }
    }
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  Future<void> _generatePdf(CreateValidationForm state) async {
    if (state.periodStart == null || state.periodEnd == null) return;
    
    // Navigation vers la page de génération PDF
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PdfGenerationPage(
          startDate: state.periodStart!,
          endDate: state.periodEnd!,
          returnPdfData: true, // Nouvelle option pour retourner les données
        ),
      ),
    );
    
    if (result != null && result['pdfBytes'] != null) {
      final pdfBytes = result['pdfBytes'] as Uint8List;
      final fileName = result['fileName'] as String? ?? 'timesheet.pdf';
      
      context.read<CreateValidationBloc>().add(
        SetPdfData(
          pdfBytes: pdfBytes,
          fileName: fileName,
        ),
      );
    }
  }
}