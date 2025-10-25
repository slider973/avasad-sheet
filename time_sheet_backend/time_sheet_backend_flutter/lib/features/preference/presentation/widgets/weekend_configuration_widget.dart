import 'package:flutter/material.dart';
import 'package:time_sheet/services/overtime_configuration_service.dart';
import 'package:time_sheet/services/injection_container.dart';

class WeekendConfigurationWidget extends StatefulWidget {
  const WeekendConfigurationWidget({super.key});

  @override
  State<WeekendConfigurationWidget> createState() =>
      _WeekendConfigurationWidgetState();
}

class _WeekendConfigurationWidgetState
    extends State<WeekendConfigurationWidget> {
  final OvertimeConfigurationService _configService =
      getIt<OvertimeConfigurationService>();

  bool _isLoading = true;

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
      // Charger la configuration des heures supplémentaires
      final enabled = await _configService.isWeekendOvertimeEnabled();
      final weekendDays = await _configService.getWeekendDays();
      final weekendRate = await _configService.getWeekendOvertimeRate();
      final weekdayRate = await _configService.getWeekdayOvertimeRate();
      final threshold = await _configService.getDailyWorkThreshold();

      if (mounted) {
        setState(() {
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Section weekend
          _buildWeekendSection(),
          const SizedBox(height: 16),

          // Section taux de majoration
          _buildOvertimeRatesSection(),

          // Section seuil journalier
          const SizedBox(height: 16),
          _buildDailyThresholdSection(),

          const SizedBox(height: 16),

          // Bouton de sauvegarde
          _buildSaveButton(),

          // Espace supplémentaire en bas pour éviter que le bouton soit collé au bord
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWeekendSection() {
    return Card(
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
                Expanded(
                  child: Text(
                    'Configuration des weekends',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                Expanded(
                  child: Text(
                    'Taux de majoration',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seuil journalier',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Seuil de référence pour définir une journée de travail normale (utilisé dans les deux modes de calcul)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Heures par jour',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_dailyWorkThreshold.inHours}h ${_dailyWorkThreshold.inMinutes.remainder(60)}min',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
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
              divisions: 240, // Permet des incréments d'1 minute
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
                  Icon(
                    Icons.info_outline,
                    color: Colors.amber.shade700,
                    size: 16,
                  ),
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
