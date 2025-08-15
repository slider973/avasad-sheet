import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/validation/presentation/bloc/create_validation/create_validation_bloc.dart';
import 'package:time_sheet/features/validation/domain/repositories/validation_repository.dart';
import 'package:time_sheet/features/pointage/presentation/pages/pdf_generation_page.dart';
import 'package:time_sheet/features/pointage/domain/entities/generated_pdf.dart';
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
  late final CreateValidationBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = di.getIt<CreateValidationBloc>()..add(const LoadManagers());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
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
                        _bloc.add(const LoadManagers());
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
                        _bloc.add(SelectManager(manager));
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

          // Section PDF à sélectionner
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
                  if (state.availablePdfs.isEmpty) ...[
                    Center(
                      child: Column(
                        children: [
                          const Icon(Icons.folder_open, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text(
                            'Aucun PDF généré',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/pdf');
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Générer un PDF'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    DropdownButtonFormField<GeneratedPdf>(
                      value: state.selectedPdf,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Sélectionner un PDF',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.picture_as_pdf),
                      ),
                      items: state.availablePdfs.map((pdf) {
                        return DropdownMenuItem(
                          value: pdf,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      pdf.fileName,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MM/yyyy').format(pdf.generatedDate),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      }).toList(),
                      onChanged: (pdf) {
                        if (pdf != null) {
                          _bloc.add(SelectGeneratedPdf(pdf));
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Veuillez sélectionner un PDF';
                        }
                        return null;
                      },
                    ),
                    if (state.selectedPdf != null && state.periodStart != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Période: ${DateFormat('MMMM yyyy', 'fr').format(state.periodEnd!)}',
                                style: const TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                            _bloc.add(
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
          value != null ? DateFormat('dd/MM/yyyy').format(value) : 'Sélectionner',
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

  Future<void> _selectMonth(BuildContext context, CreateValidationForm state) async {
    final DateTime initialDate = state.periodStart ?? DateTime.now();

    // Utiliser le month picker existant
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('fr', 'FR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Définir le premier et dernier jour du mois
      final firstDay = DateTime(picked.year, picked.month, 1);
      final lastDay = DateTime(picked.year, picked.month + 1, 0);

      _bloc.add(SelectPeriod(
        startDate: firstDay,
        endDate: lastDay,
      ));
    }
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

      _bloc.add(
        SetPdfData(
          pdfBytes: pdfBytes,
          fileName: fileName,
        ),
      );
    }
  }
}
