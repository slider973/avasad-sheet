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
  bool _weekendOvertimeEnabled = true;
  List<int> _weekendDays = [DateTime.saturday, DateTime.sunday];
  double _weekendOvertimeRate = 1.5;
  double _weekdayOvertimeRate = 1.25;
  Duration _dailyWorkThreshold = const Duration(hours: 8);

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
          _buildWeekendOvertimeSection(),
          const SizedBox(height: 24),
          _buildWeekendDaysSection(),
          const SizedBox(height: 24),
          _buildOvertimeRatesSection(),
          const SizedBox(height: 24),
          _buildWorkThresholdSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildWeekendOvertimeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heures supplémentaires automatiques',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activer automatiquement les heures supplémentaires pour le travail effectué le weekend',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Activer les heures supplémentaires weekend'),
              value: _weekendOvertimeEnabled,
              onChanged: (value) {
                setState(() {
                  _weekendOvertimeEnabled = value;
                });
              },
              activeColor: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekendDaysSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jours de weekend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les jours considérés comme weekend',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
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
                activeColor: Colors.teal,
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
            Text(
              'Taux de majoration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
            ),
            const SizedBox(height: 16),
            _buildRateSlider(
              'Taux semaine',
              _weekdayOvertimeRate,
              (value) => setState(() => _weekdayOvertimeRate = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(value * 100).toInt()}%'),
          ],
        ),
        Slider(
          value: value,
          min: 1.0,
          max: 2.0,
          divisions: 20,
          onChanged: onChanged,
          activeColor: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildWorkThresholdSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seuil journalier',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                Text('${_dailyWorkThreshold.inHours}h'),
              ],
            ),
            Slider(
              value: _dailyWorkThreshold.inHours.toDouble(),
              min: 6.0,
              max: 10.0,
              divisions: 8,
              onChanged: (value) {
                setState(() {
                  _dailyWorkThreshold = Duration(hours: value.toInt());
                });
              },
              activeColor: Colors.teal,
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
          backgroundColor: Colors.teal,
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
