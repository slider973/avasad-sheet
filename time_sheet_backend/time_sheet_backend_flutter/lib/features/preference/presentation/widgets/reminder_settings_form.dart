import 'package:flutter/material.dart';

import '../../data/models/reminder_settings.dart';

/// Form widget for configuring detailed reminder settings
class ReminderSettingsForm extends StatefulWidget {
  final ReminderSettings reminderSettings;
  final ValueChanged<ReminderSettings> onSettingsChanged;

  const ReminderSettingsForm({
    super.key,
    required this.reminderSettings,
    required this.onSettingsChanged,
  });

  @override
  State<ReminderSettingsForm> createState() => _ReminderSettingsFormState();
}

class _ReminderSettingsFormState extends State<ReminderSettingsForm> {
  late ReminderSettings _currentSettings;

  @override
  void initState() {
    super.initState();
    _currentSettings = widget.reminderSettings;
  }

  @override
  void didUpdateWidget(ReminderSettingsForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reminderSettings != widget.reminderSettings) {
      _currentSettings = widget.reminderSettings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeSettingsCard(),
          const SizedBox(height: 16),
          _buildDaySelectionCard(),
          const SizedBox(height: 16),
          _buildAdvancedSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildTimeSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Horaires de rappel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimePickerTile(
              title: 'Heure de pointage d\'entrée',
              subtitle: 'Rappel pour pointer l\'arrivée',
              time: _currentSettings.clockInTime,
              icon: Icons.login,
              onTimeChanged: (time) {
                _updateSettings(_currentSettings.copyWith(clockInTime: time));
              },
            ),
            const Divider(),
            _buildTimePickerTile(
              title: 'Heure de pointage de sortie',
              subtitle: 'Rappel pour pointer le départ',
              time: _currentSettings.clockOutTime,
              icon: Icons.logout,
              onTimeChanged: (time) {
                _updateSettings(_currentSettings.copyWith(clockOutTime: time));
              },
            ),
            if (_hasTimeValidationError()) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'L\'heure de sortie doit être après l\'heure d\'entrée',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required IconData icon,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.teal),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.teal[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal[200]!),
        ),
        child: Text(
          _formatTime(time),
          style: TextStyle(
            color: Colors.teal[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      onTap: () => _showTimePicker(context, time, onTimeChanged),
    );
  }

  Widget _buildDaySelectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Jours actifs',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez les jours où vous souhaitez recevoir des rappels',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            _buildDaySelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final days = [
      {'name': 'Lun', 'value': 1},
      {'name': 'Mar', 'value': 2},
      {'name': 'Mer', 'value': 3},
      {'name': 'Jeu', 'value': 4},
      {'name': 'Ven', 'value': 5},
      {'name': 'Sam', 'value': 6},
      {'name': 'Dim', 'value': 7},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: days.map((day) {
        final isSelected = _currentSettings.activeDays.contains(day['value']);
        return FilterChip(
          label: Text(day['name'] as String),
          selected: isSelected,
          onSelected: (selected) {
            final newActiveDays = Set<int>.from(_currentSettings.activeDays);
            if (selected) {
              newActiveDays.add(day['value'] as int);
            } else {
              newActiveDays.remove(day['value'] as int);
            }

            // Ensure at least one day is selected
            if (newActiveDays.isNotEmpty) {
              _updateSettings(
                  _currentSettings.copyWith(activeDays: newActiveDays));
            } else {
              _showNoDaysSelectedError();
            }
          },
          selectedColor: Colors.teal[100],
          checkmarkColor: Colors.teal[700],
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Paramètres avancés',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Icon(Icons.event_busy, color: Colors.teal),
              title: const Text('Respecter les jours fériés'),
              subtitle:
                  const Text('Ne pas envoyer de rappels les jours fériés'),
              value: _currentSettings.respectHolidays,
              activeThumbColor: Colors.teal,
              onChanged: (value) {
                _updateSettings(
                    _currentSettings.copyWith(respectHolidays: value));
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.snooze, color: Colors.teal),
              title: const Text('Durée de report'),
              subtitle: Text('${_currentSettings.snoozeMinutes} minutes'),
              trailing: DropdownButton<int>(
                value: _currentSettings.snoozeMinutes,
                items: [5, 10, 15, 30].map((minutes) {
                  return DropdownMenuItem(
                    value: minutes,
                    child: Text('$minutes min'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(
                        _currentSettings.copyWith(snoozeMinutes: value));
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.repeat, color: Colors.teal),
              title: const Text('Reports maximum'),
              subtitle:
                  Text('${_currentSettings.maxSnoozes} reports par rappel'),
              trailing: DropdownButton<int>(
                value: _currentSettings.maxSnoozes,
                items: [0, 1, 2, 3].map((count) {
                  return DropdownMenuItem(
                    value: count,
                    child: Text('$count'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _updateSettings(
                        _currentSettings.copyWith(maxSnoozes: value));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSettings(ReminderSettings newSettings) {
    setState(() {
      _currentSettings = newSettings;
    });
    widget.onSettingsChanged(newSettings);
  }

  Future<void> _showTimePicker(
    BuildContext context,
    TimeOfDay initialTime,
    ValueChanged<TimeOfDay> onTimeChanged,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.teal,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != initialTime) {
      onTimeChanged(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool _hasTimeValidationError() {
    final clockInMinutes = _currentSettings.clockInTime.hour * 60 +
        _currentSettings.clockInTime.minute;
    final clockOutMinutes = _currentSettings.clockOutTime.hour * 60 +
        _currentSettings.clockOutTime.minute;
    return clockOutMinutes <= clockInMinutes;
  }

  void _showNoDaysSelectedError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Au moins un jour doit être sélectionné'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
