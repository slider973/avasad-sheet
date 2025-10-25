import 'package:flutter/material.dart';
import '../../../../services/overtime_settings_migration_service.dart';
import 'overtime_calculation_mode_widget.dart';

/// Widget d'information sur la migration des paramètres d'heures supplémentaires
class OvertimeMigrationInfoWidget extends StatefulWidget {
  final VoidCallback? onDismiss;

  const OvertimeMigrationInfoWidget({
    super.key,
    this.onDismiss,
  });

  @override
  State<OvertimeMigrationInfoWidget> createState() =>
      _OvertimeMigrationInfoWidgetState();
}

class _OvertimeMigrationInfoWidgetState
    extends State<OvertimeMigrationInfoWidget> {
  final OvertimeSettingsMigrationService _migrationService =
      OvertimeSettingsMigrationService();
  MigrationReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMigrationReport();
  }

  Future<void> _loadMigrationReport() async {
    try {
      final report = await _migrationService.getMigrationReport();
      if (mounted) {
        setState(() {
          _report = report;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_report == null || !_report!.migrationCompleted) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildMigrationInfo(context),
            const SizedBox(height: 16),
            _buildNewFeatures(context),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.upgrade,
            color: Colors.blue.shade700,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouveau système d\'heures supplémentaires',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
              ),
              Text(
                'Vos paramètres ont été migrés automatiquement',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: widget.onDismiss,
          icon: const Icon(Icons.close),
          tooltip: 'Fermer',
        ),
      ],
    );
  }

  Widget _buildMigrationInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                'Migration réussie',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Votre mode de calcul actuel : ${_report!.currentMode.displayName}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            _getMigrationExplanation(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                ),
          ),
        ],
      ),
    );
  }

  String _getMigrationExplanation() {
    if (_report!.currentMode == OvertimeCalculationMode.daily) {
      return 'Vos heures supplémentaires continuent d\'être calculées jour par jour comme avant.';
    } else {
      return 'Vos heures supplémentaires sont maintenant calculées avec compensation mensuelle pour plus d\'équité.';
    }
  }

  Widget _buildNewFeatures(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nouvelles fonctionnalités disponibles',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          context,
          Icons.calculate,
          'Calcul mensuel avec compensation',
          'Les déficits d\'heures sont compensés par les excès du mois',
        ),
        _buildFeatureItem(
          context,
          Icons.compare_arrows,
          'Comparaison des modes',
          'Comparez les résultats entre les deux modes de calcul',
        ),
        _buildFeatureItem(
          context,
          Icons.analytics,
          'Statistiques détaillées',
          'Visualisez vos déficits, compensations et heures supplémentaires réelles',
        ),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Naviguer vers les paramètres d'heures supplémentaires
              Navigator.of(context).pushNamed('/overtime-settings');
            },
            icon: const Icon(Icons.settings),
            label: const Text('Voir les paramètres'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Naviguer vers la comparaison des modes
              Navigator.of(context).pushNamed('/overtime-comparison');
            },
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Comparer les modes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget simplifié pour afficher juste une notification de migration
class OvertimeMigrationBanner extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const OvertimeMigrationBanner({
    super.key,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Material(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.upgrade,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nouveau système d\'heures supplémentaires',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                      ),
                      Text(
                        'Découvrez le calcul mensuel avec compensation',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue.shade600,
                  size: 16,
                ),
                if (onDismiss != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(
                      Icons.close,
                      color: Colors.blue.shade600,
                      size: 16,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
