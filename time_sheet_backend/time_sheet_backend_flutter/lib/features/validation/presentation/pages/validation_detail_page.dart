import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:time_sheet/features/validation/presentation/bloc/validation_detail/validation_detail_bloc.dart';
import 'package:time_sheet/features/validation/domain/entities/validation_request.dart';
import 'package:time_sheet/features/validation/domain/services/validation_overtime_analyzer.dart';
import 'package:time_sheet/features/validation/presentation/widgets/weekend_overtime_summary_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:time_sheet/features/preference/presentation/manager/preferences_bloc.dart';
/// Page de détail d'une validation
class ValidationDetailPage extends StatefulWidget {
  final String validationId;
  final bool isManager;

  const ValidationDetailPage({
    super.key,
    required this.validationId,
    required this.isManager,
  });

  @override
  State<ValidationDetailPage> createState() => _ValidationDetailPageState();
}

class _ValidationDetailPageState extends State<ValidationDetailPage> {
  final _commentController = TextEditingController();
  Uint8List? _managerSignature;
  final ValidationOvertimeAnalyzer _overtimeAnalyzer =
      ValidationOvertimeAnalyzer();

  @override
  void initState() {
    super.initState();
    context.read<ValidationDetailBloc>().add(
          LoadValidationDetail(widget.validationId),
        );

    // Charger les données timesheet si c'est un manager
    if (widget.isManager) {
      context.read<ValidationDetailBloc>().add(
            LoadValidationTimesheetData(widget.validationId),
          );
      _loadManagerSignature();
    }
  }

  void _loadManagerSignature() {
    final preferencesState = context.read<PreferencesBloc>().state;
    if (preferencesState is PreferencesLoaded) {
      if (preferencesState.signature != null) {
        setState(() {
          _managerSignature = preferencesState.signature;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la validation'),
        actions: [
          BlocBuilder<ValidationDetailBloc, ValidationDetailState>(
            builder: (context, state) {
              String? validationId;
              if (state is ValidationDetailLoaded) {
                validationId = state.validation.id;
              } else if (state is ValidationDetailWithTimesheetLoaded) {
                validationId = state.validation.id;
              }
              if (validationId != null) {
                return IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () => _downloadPdf(validationId!),
                  tooltip: 'Télécharger le PDF',
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: BlocConsumer<ValidationDetailBloc, ValidationDetailState>(
        listener: (context, state) {
          if (state is ValidationDetailSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }

          if (state is SigningLinkGenerated) {
            Clipboard.setData(ClipboardData(text: state.signingUrl));
            final roleLabel = state.signerRole == 'manager' ? 'manager' : 'client';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lien de signature $roleLabel copié dans le presse-papier'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }

          if (state is ValidationDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ValidationDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ValidationDetailError &&
              state is! ValidationDetailLoaded) {
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
                      context.read<ValidationDetailBloc>().add(
                            LoadValidationDetail(widget.validationId),
                          );
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is ValidationDetailLoaded) {
            return _buildContent(state.validation);
          }

          if (state is ValidationDetailWithTimesheetLoaded) {
            return _buildContentWithTimesheet(
                state.validation, state.timesheetData);
          }

          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildContent(ValidationRequest validation) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Carte d'information principale
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Informations générales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStatusChip(validation.status),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.date_range,
                  'Période',
                  '${dateFormat.format(validation.periodStart)} - ${dateFormat.format(validation.periodEnd)}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.access_time,
                  'Créée le',
                  dateTimeFormat.format(validation.createdAt),
                ),
                if (validation.validatedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.check_circle,
                    'Validée le',
                    dateTimeFormat.format(validation.validatedAt!),
                  ),
                ],
                if (validation.expiresAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.timer_off,
                    'Expire le',
                    dateTimeFormat.format(validation.expiresAt!),
                    color: validation.isExpired ? Colors.red : null,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Progression des signatures (multi-acteurs)
        ..._buildSigningProgress(validation),

        // Document PDF
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf,
                      size: 40, color: Colors.red),
                  title: const Text('Timesheet.pdf'),
                  subtitle: Text(
                      validation.pdfSizeBytes > 0
                          ? 'Taille: ${_formatFileSize(validation.pdfSizeBytes)}'
                          : _formatFileSize(validation.pdfSizeBytes)),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadPdf(validation.id),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Commentaire et signature du manager pour les validations approuvées
        if (validation.isApproved &&
            (validation.managerComment != null ||
                validation.managerSignature != null)) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Validation du manager',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  if (validation.managerComment != null &&
                      validation.managerComment!.isNotEmpty) ...[
                    const Text(
                      'Commentaire',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(validation.managerComment!),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (validation.managerSignature != null &&
                      validation.managerSignature!.isNotEmpty) ...[
                    const Text(
                      'Signature',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(validation.managerSignature!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Commentaire du manager pour les validations rejetées
        if (validation.isRejected &&
            validation.managerComment != null &&
            validation.managerComment!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Raison du rejet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(validation.managerComment!),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Actions pour le manager
        if (widget.isManager && validation.isPending) ...[
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (optionnel pour approbation)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Signature',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _managerSignature != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _managerSignature!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Aucune signature trouvée.\nVeuillez configurer votre signature dans les paramètres.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showRejectConfirmation(validation.id),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Rejeter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _managerSignature != null
                              ? () => _showApproveConfirmation(validation.id)
                              : null,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Approuver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildContentWithTimesheet(
      ValidationRequest validation, Map<String, dynamic> timesheetData) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Carte d'information principale
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Informations générales',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildStatusChip(validation.status),
                  ],
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  Icons.date_range,
                  'Période',
                  '${dateFormat.format(validation.periodStart)} - ${dateFormat.format(validation.periodEnd)}',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  Icons.access_time,
                  'Créée le',
                  dateTimeFormat.format(validation.createdAt),
                ),
                if (validation.validatedAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.check_circle,
                    'Validée le',
                    dateTimeFormat.format(validation.validatedAt!),
                  ),
                ],
                if (validation.expiresAt != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.timer_off,
                    'Expire le',
                    dateTimeFormat.format(validation.expiresAt!),
                    color: validation.isExpired ? Colors.red : null,
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Résumé des heures supplémentaires weekend
        FutureBuilder(
          future: _overtimeAnalyzer.analyzeTimesheetData(timesheetData),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final overtimeSummary = snapshot.data!;
              return WeekendOvertimeSummaryWidget(
                overtimeSummary: overtimeSummary,
                showAlert: widget.isManager && validation.isPending,
              );
            } else if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                      'Erreur lors du calcul des heures: ${snapshot.error}'),
                ),
              );
            } else {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // Progression des signatures (multi-acteurs)
        ..._buildSigningProgress(validation),

        // Document PDF
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf,
                      size: 40, color: Colors.red),
                  title: const Text('Timesheet.pdf'),
                  subtitle: Text(
                      validation.pdfSizeBytes > 0
                          ? 'Taille: ${_formatFileSize(validation.pdfSizeBytes)}'
                          : _formatFileSize(validation.pdfSizeBytes)),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () => _downloadPdf(validation.id),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Commentaire et signature du manager pour les validations approuvées
        if (validation.isApproved &&
            (validation.managerComment != null ||
                validation.managerSignature != null)) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Validation du manager',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  if (validation.managerComment != null &&
                      validation.managerComment!.isNotEmpty) ...[
                    const Text(
                      'Commentaire',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(validation.managerComment!),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (validation.managerSignature != null &&
                      validation.managerSignature!.isNotEmpty) ...[
                    const Text(
                      'Signature',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(validation.managerSignature!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // Commentaire du manager pour les validations rejetées
        if (validation.isRejected &&
            validation.managerComment != null &&
            validation.managerComment!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Raison du rejet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const Divider(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(validation.managerComment!),
                  ),
                ],
              ),
            ),
          ),
        ],

        // Actions pour le manager
        if (widget.isManager && validation.isPending) ...[
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 24),
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Commentaire (optionnel pour approbation)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Signature',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _managerSignature != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _managerSignature!,
                              fit: BoxFit.contain,
                            ),
                          )
                        : const Center(
                            child: Text(
                              'Aucune signature trouvée.\nVeuillez configurer votre signature dans les paramètres.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _showRejectConfirmation(validation.id),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Rejeter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _managerSignature != null
                              ? () => _showApproveConfirmation(validation.id)
                              : null,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Approuver'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  List<Widget> _buildSigningProgress(ValidationRequest validation) {
    if (validation.signingStep == null) return [];

    return [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progression des signatures',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              _buildSigningStep(
                'Employé',
                Icons.person,
                _isStepCompleted(validation, 'employee'),
                _isStepCurrent(validation, 'employee'),
              ),
              const SizedBox(height: 8),
              _buildSigningStep(
                'Manager',
                Icons.supervisor_account,
                _isStepCompleted(validation, 'manager'),
                _isStepCurrent(validation, 'manager'),
                rejected: _isStepRejected(validation, 'manager'),
              ),
              // Bouton pour générer le lien de signature manager (pour managers externes)
              if (_isStepCurrent(validation, 'manager') &&
                  validation.isPending) ...[
                const SizedBox(height: 8),
                _buildSigningLinkButton(
                  validation: validation,
                  signerRole: 'manager',
                  label: 'Copier le lien de signature manager',
                  icon: Icons.link,
                ),
              ],
              if (validation.clientSignerName != null &&
                  validation.clientSignerName!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSigningStep(
                  'Client (${validation.clientSignerName})',
                  Icons.business,
                  _isStepCompleted(validation, 'client'),
                  _isStepCurrent(validation, 'client'),
                ),
                // Bouton pour copier le lien de signature client
                if (_isStepCurrent(validation, 'client')) ...[
                  const SizedBox(height: 8),
                  _buildSigningLinkButton(
                    validation: validation,
                    signerRole: 'client',
                    label: 'Copier le lien de signature client',
                    icon: Icons.share,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildSigningLinkButton({
    required ValidationRequest validation,
    required String signerRole,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 36),
      child: OutlinedButton.icon(
        onPressed: () {
          context.read<ValidationDetailBloc>().add(
                GenerateSigningLink(
                  validationId: validation.id,
                  signerRole: signerRole,
                ),
              );
        },
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: const BorderSide(color: Colors.blue),
        ),
      ),
    );
  }

  /// Détermine si une étape de signature est complétée en se basant sur le signing_step
  bool _isStepCompleted(ValidationRequest validation, String step) {
    final signingStep = validation.signingStep ?? 'employee';
    switch (step) {
      case 'employee':
        // L'employé a signé dès la création de la validation
        return true;
      case 'manager':
        // Manager a signé si on est passé à l'étape client ou completed, ou si approuvé
        return signingStep == 'client' || signingStep == 'completed' || validation.isApproved;
      case 'client':
        return signingStep == 'completed' && validation.isApproved;
      default:
        return false;
    }
  }

  /// Détermine si une étape est en cours d'attente
  bool _isStepCurrent(ValidationRequest validation, String step) {
    final signingStep = validation.signingStep ?? 'manager';
    switch (step) {
      case 'manager':
        return signingStep == 'manager' && validation.isPending;
      case 'client':
        return signingStep == 'client' && !validation.isRejected;
      default:
        return false;
    }
  }

  /// Détermine si une étape a été rejetée
  bool _isStepRejected(ValidationRequest validation, String step) {
    return step == 'manager' && validation.isRejected;
  }

  Widget _buildSigningStep(String label, IconData icon, bool completed, bool current, {bool rejected = false}) {
    Color color;
    IconData statusIcon;
    String statusText;
    if (rejected) {
      color = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Rejeté';
    } else if (completed) {
      color = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Signé';
    } else if (current) {
      color = Colors.orange;
      statusIcon = Icons.hourglass_top;
      statusText = 'En attente';
    } else {
      color = Colors.grey.shade400;
      statusIcon = Icons.radio_button_unchecked;
      statusText = 'En attente';
    }

    return Row(
      children: [
        Icon(statusIcon, color: color, size: 24),
        const SizedBox(width: 12),
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: completed || current || rejected ? null : Colors.grey,
              fontWeight: current ? FontWeight.bold : null,
            ),
          ),
        ),
        Text(statusText, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            color: color ?? Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: color != null ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ValidationStatus status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);
    final icon = _getStatusIcon(status);

    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }

  Color _getStatusColor(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
      case ValidationStatus.signing:
        return Colors.orange;
      case ValidationStatus.approved:
        return Colors.green;
      case ValidationStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusLabel(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
      case ValidationStatus.signing:
        return 'En attente';
      case ValidationStatus.approved:
        return 'Approuvée';
      case ValidationStatus.rejected:
        return 'Rejetée';
    }
  }

  IconData _getStatusIcon(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.pending:
      case ValidationStatus.signing:
        return Icons.schedule;
      case ValidationStatus.approved:
        return Icons.check_circle;
      case ValidationStatus.rejected:
        return Icons.cancel;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Document PDF';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showApproveConfirmation(String validationId) {
    final bloc = context.read<ValidationDetailBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer l\'approbation'),
        content: const Text(
          'Êtes-vous sûr de vouloir approuver cette timesheet ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(
                ApproveValidation(
                  validationId: validationId,
                  managerSignature: _managerSignature != null
                      ? base64Encode(_managerSignature!)
                      : '',
                  comment: _commentController.text.isNotEmpty
                      ? _commentController.text
                      : null,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(String validationId) {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Un commentaire est requis pour rejeter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final bloc = context.read<ValidationDetailBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer le rejet'),
        content: const Text(
          'Êtes-vous sûr de vouloir rejeter cette timesheet ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(
                RejectValidation(
                  validationId: validationId,
                  comment: _commentController.text,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(String validationId) async {
    // Si c'est un manager ET que la validation est approuvée, envoyer la signature
    String? managerSignature;
    if (widget.isManager && _managerSignature != null) {
      managerSignature = base64Encode(_managerSignature!);
    }

    // Télécharger le PDF depuis le serveur
    context.read<ValidationDetailBloc>().add(
          DownloadValidationPdf(validationId, managerSignature),
        );

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Téléchargement du PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Attendre le résultat
    final bloc = context.read<ValidationDetailBloc>();
    bloc.stream
        .firstWhere((state) =>
            state is ValidationDetailPdfDownloaded ||
            state is ValidationDetailError)
        .then((state) {
      Navigator.pop(context); // Fermer le dialog

      if (state is ValidationDetailPdfDownloaded) {
        _openPdf(state.pdfBytes, state.fileName);
      }

      // Recharger les données pour restaurer la page
      if (widget.isManager) {
        bloc.add(LoadValidationTimesheetData(validationId));
      } else {
        bloc.add(LoadValidationDetail(validationId));
      }
    });
  }

  Future<void> _openPdf(List<int> bytes, String fileName) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le fichier: ${result.message}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'ouverture du PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
