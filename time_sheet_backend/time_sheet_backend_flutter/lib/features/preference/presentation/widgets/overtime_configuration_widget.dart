import 'package:flutter/material.dart';
import 'package:time_sheet/services/overtime_configuration_service.dart';
import 'package:time_sheet/services/overtime_calculation_mode_service.dart';
import 'package:time_sheet/services/injection_container.dart';
import 'overtime_calculation_mode_widget.dart';

/// Widget principal pour configurer tous les aspects des heures supplémentaires
class OvertimeConfigurationWidget extends StatefulWidget {
  const OvertimeConfigurationWidget({super.key});

  @override
  State<OvertimeConfigurationWidget> createState() =>
      _OvertimeConfigurationWidgetState();
}

class _OvertimeConfigurationWidgetState
    extends State<OvertimeConfigurationWidget> {
  final OvertimeConfigurationService _configService =
      getIt<OvertimeConfigurationService>();
  final OvertimeCalculationModeService _modeService =
      OvertimeCalculationModeService();

  bool _isLoading = true;

  // Configuration du mode de calcul
  OvertimeCalculationMode _calculationMode = OvertimeCalculationMode.daily;

  // Configuration des weekends
  bool _weekendOvertimeEnabled = true;
  List<int> _weekendDays = [DateTime.saturday, DateTime.sunday];

  // Configuration des taux
  double _weekendOvertimeRate = 1.5;
  double _weekdayOvertimeRate = 1.25;

  // Configuration du seuil journalier (utilisé seulement en mode journalier)
  Duration _dailyWorkThreshold = const Duration(hours: 8, minutes: 18);

  final Map<int, String> _dayNames = {
    DateTime.monday: 'Lundi',
    DateTime.tuesday: 'Mardi',
    DateTime.wednesday: 'Mercredi',
    DateTime.thursday: 'Jeudi',
    DateTime.friday: 'Vendredi',
    DateTime.saturday: 'Samedi',
    DateTime.sunday: 'Dimanche',
  };

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      // Charger le mode de calcul
      final mode = await _modeService.getCurrentMode();

      // Charger la configuration des heures supplémentaires
      final enabled = await _configService.isWeekendOvertimeEnabled();
      final weekendDays = await _configService.getWeekendDays();
      final weekendRate = await _configService.getWeekendOvertimeRate();
      final weekdayRate = await _configService.getWeekdayOvertimeRate();
      final threshold = await _configService.getDailyWorkThreshold();

      if (mounted) {
        setState(() {
          _calculationMode = mode;
          _weekendOvertimeEnabled = enabled;
          _weekendDays = weekendDays;
          _weekendOvertimeRate = weekendRate;
          _weekdayOvertimeRate = weekdayRate;
          _dailyWorkThreshold = threshold;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      // Sauvegarder le mode de calcul
      await _modeService.setCalculationMode(_calculationMode);

      // Sauvegarder la configuration des heures supplémentaires
      await _configService.setWeekendOvertimeEnabled(_weekendOvertimeEnabled);
      await _configService.setWeekendDays(_weekendDays);
      await _configService.setWeekendOvertimeRate(_weekendOvertimeRate);
      await _configService.setWeekdayOvertimeRate(_weekdayOvertimeRate);
      await _configService.setDailyWorkThreshold(_dailyWorkThreshold);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Configuration sauvegardée avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section principale : Mode de calcul
          _buildCalculationModeSection(),
          const SizedBox(height: 24),

          // Section weekend
          _buildWeekendSection(),
          const SizedBox(height: 24),

          // Section taux de majoration
          _buildOvertimeRatesSection(),
          const SizedBox(height: 24),

          // Section seuil journalier (seulement en mode journalier)
          if (_calculationMode == OvertimeCalculationMode.daily) ...[
            _buildDailyThresholdSection(),
            const SizedBox(height: 24),
          ],

          // Bouton de sauvegarde
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCalculationModeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mode de calcul des heures supplémentaires',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez comment calculer vos heures supplémentaires',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),

            // Mode journalier
            _buildModeOption(
              mode: OvertimeCalculationMode.daily,
              title: 'Calcul journalier',
              subtitle: 'Heures sup calculées jour par jour',
              description:
                  'Chaque jour dépassant le seuil génère des heures supplémentaires immédiatement.',
              icon: Icons.today,
            ),

            const SizedBox(height: 12),

            // Mode mensuel
            _buildModeOption(
              mode: OvertimeCalculationMode.monthlyWithCompensation,
              title: 'Calcul mensuel avec compensation',
              subtitle: 'Déficits compensés par les excès du mois',
              description:
                  'Les jours avec moins d\'heures sont compensés par les jours avec plus d\'heures. Plus équitable.',
              icon: Icons.calendar_month,
            ),

            const SizedBox(height: 16),
            _buildModeExplanation(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required OvertimeCalculationMode mode,
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _calculationMode == mode;

    return InkWell(
      onTap: () => setState(() => _calculationMode = mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Radio<OvertimeCalculationMode>(
              value: mode,
              groupValue: _calculationMode,
              onChanged: (value) => setState(() => _calculationMode = value!),
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeExplanation() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Exemple de différence',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Semaine avec : Lundi 6h, Mardi 10h30',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          _buildExampleRow(
            'Calcul journalier :',
            'Lundi: 0h sup, Mardi: 2h12 sup = 2h12 total',
            Colors.orange.shade700,
          ),
          const SizedBox(height: 4),
          _buildExampleRow(
            'Calcul mensuel :',
            'Total: 16h30, Attendu: 16h36 = 0h sup (déficit de 6min)',
            Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildExampleRow(String label, String calculation, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
              ),
              Text(
                calculation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeekendSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.weekend,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Configuration des weekends',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configurez les jours de weekend et l\'activation des heures supplémentaires',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),

            // Activation des heures supplémentaires weekend
            SwitchListTile(
              title:
                  const Text('Heures supplémentaires automatiques le weekend'),
              subtitle: const Text(
                  'Toutes les heures travaillées le weekend sont des heures supplémentaires'),
              value: _weekendOvertimeEnabled,
              onChanged: (value) =>
                  setState(() => _weekendOvertimeEnabled = value),
              activeColor: Theme.of(context).primaryColor,
            ),

            const SizedBox(height: 16),

            // Sélection des jours de weekend
            Text(
              'Jours considérés comme weekend',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            ...List.generate(7, (index) {
              final dayOfWeek = index + 1;
              final isSelected = _weekendDays.contains(dayOfWeek);

              return CheckboxListTile(
                title: Text(_dayNames[dayOfWeek] ?? ''),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      if (!_weekendDays.contains(dayOfWeek)) {
                        _weekendDays.add(dayOfWeek);
                      }
                    } else {
                      _weekendDays.remove(dayOfWeek);
                    }
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOvertimeRatesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Taux de majoration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configurez les taux de majoration pour les heures supplémentaires',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            _buildRateSlider(
              'Taux weekend',
              _weekendOvertimeRate,
              (value) => setState(() => _weekendOvertimeRate = value),
              Colors.purple,
            ),
            const SizedBox(height: 16),
            _buildRateSlider(
              'Taux semaine',
              _weekdayOvertimeRate,
              (value) => setState(() => _weekdayOvertimeRate = value),
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateSlider(
    String label,
    double value,
    ValueChanged<double> onChanged,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(value * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: 1.0,
          max: 2.0,
          divisions: 20,
          onChanged: onChanged,
          activeColor: color,
        ),
      ],
    );
  }

  Widget _buildDailyThresholdSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Seuil journalier (mode journalier uniquement)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Nombre d\'heures de travail normal par jour avant heures supplémentaires',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Heures par jour'),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_dailyWorkThreshold.inHours}h ${_dailyWorkThreshold.inMinutes.remainder(60)}min',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: _dailyWorkThreshold.inMinutes.toDouble(),
              min: 360.0, // 6h00
              max: 600.0, // 10h00
              divisions: 240,
              onChanged: (value) {
                setState(() {
                  _dailyWorkThreshold = Duration(minutes: value.toInt());
                });
              },
              activeColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.amber.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Valeur recommandée: 8h18 (498 minutes)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveConfiguration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Sauvegarder la configuration',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
