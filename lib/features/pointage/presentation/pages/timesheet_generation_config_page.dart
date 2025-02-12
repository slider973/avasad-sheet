import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:time_sheet/features/pointage/domain/entities/timesheet_generation_config.dart';
import 'package:time_sheet/features/pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

class TimesheetGenerationConfigPage extends StatefulWidget {
  @override
  _TimesheetGenerationConfigPageState createState() => _TimesheetGenerationConfigPageState();
}

class _TimesheetGenerationConfigPageState extends State<TimesheetGenerationConfigPage> {
  late TimesheetGenerationConfig config;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    config = TimesheetGenerationConfig.defaultConfig();
  }

  TimeOfDay _dateTimeToTimeOfDay(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  DateTime _timeOfDayToDateTime(TimeOfDay timeOfDay) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);
  }

  Future<void> _selectTime(BuildContext context, String label, DateTime initialTime, Function(DateTime) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dateTimeToTimeOfDay(initialTime),
    );
    if (picked != null) {
      onTimeSelected(_timeOfDayToDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuration de la génération'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            _buildTimeRangeSection(
              'Heure d\'arrivée',
              config.startTimeMin,
              config.startTimeMax,
              (time) => setState(() => config = TimesheetGenerationConfig(
                startTimeMin: time,
                startTimeMax: config.startTimeMax,
                lunchStartMin: config.lunchStartMin,
                lunchStartMax: config.lunchStartMax,
                lunchDurationMin: config.lunchDurationMin,
                lunchDurationMax: config.lunchDurationMax,
                endTimeMax: config.endTimeMax,
              )),
              (time) => setState(() => config = TimesheetGenerationConfig(
                startTimeMin: config.startTimeMin,
                startTimeMax: time,
                lunchStartMin: config.lunchStartMin,
                lunchStartMax: config.lunchStartMax,
                lunchDurationMin: config.lunchDurationMin,
                lunchDurationMax: config.lunchDurationMax,
                endTimeMax: config.endTimeMax,
              )),
            ),
            _buildTimeRangeSection(
              'Heure de pause déjeuner',
              config.lunchStartMin,
              config.lunchStartMax,
              (time) => setState(() => config = TimesheetGenerationConfig(
                startTimeMin: config.startTimeMin,
                startTimeMax: config.startTimeMax,
                lunchStartMin: time,
                lunchStartMax: config.lunchStartMax,
                lunchDurationMin: config.lunchDurationMin,
                lunchDurationMax: config.lunchDurationMax,
                endTimeMax: config.endTimeMax,
              )),
              (time) => setState(() => config = TimesheetGenerationConfig(
                startTimeMin: config.startTimeMin,
                startTimeMax: config.startTimeMax,
                lunchStartMin: config.lunchStartMin,
                lunchStartMax: time,
                lunchDurationMin: config.lunchDurationMin,
                lunchDurationMax: config.lunchDurationMax,
                endTimeMax: config.endTimeMax,
              )),
            ),
            _buildDurationRangeSection(),
            _buildEndTimeSection(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  context.read<TimeSheetBloc>().add(
                    GenerateMonthlyTimesheetEvent(config: config),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Générer le timesheet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSection(
    String label,
    DateTime minTime,
    DateTime maxTime,
    Function(DateTime) onMinSelected,
    Function(DateTime) onMaxSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: Text('Minimum'),
                subtitle: Text('${_dateTimeToTimeOfDay(minTime).format(context)}'),
                onTap: () => _selectTime(context, 'Minimum', minTime, onMinSelected),
              ),
            ),
            Expanded(
              child: ListTile(
                title: Text('Maximum'),
                subtitle: Text('${_dateTimeToTimeOfDay(maxTime).format(context)}'),
                onTap: () => _selectTime(context, 'Maximum', maxTime, onMaxSelected),
              ),
            ),
          ],
        ),
        Divider(),
      ],
    );
  }

  Widget _buildDurationRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Durée de la pause déjeuner (minutes)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: config.lunchDurationMin.toString(),
                decoration: InputDecoration(labelText: 'Minimum'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requis';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration < 0) {
                    return 'Durée invalide';
                  }
                  return null;
                },
                onChanged: (value) {
                  final duration = int.tryParse(value);
                  if (duration != null) {
                    setState(() => config = TimesheetGenerationConfig(
                      startTimeMin: config.startTimeMin,
                      startTimeMax: config.startTimeMax,
                      lunchStartMin: config.lunchStartMin,
                      lunchStartMax: config.lunchStartMax,
                      lunchDurationMin: duration,
                      lunchDurationMax: config.lunchDurationMax,
                      endTimeMax: config.endTimeMax,
                    ));
                  }
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: config.lunchDurationMax.toString(),
                decoration: InputDecoration(labelText: 'Maximum'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Requis';
                  }
                  final duration = int.tryParse(value);
                  if (duration == null || duration < 0) {
                    return 'Durée invalide';
                  }
                  return null;
                },
                onChanged: (value) {
                  final duration = int.tryParse(value);
                  if (duration != null) {
                    setState(() => config = TimesheetGenerationConfig(
                      startTimeMin: config.startTimeMin,
                      startTimeMax: config.startTimeMax,
                      lunchStartMin: config.lunchStartMin,
                      lunchStartMax: config.lunchStartMax,
                      lunchDurationMin: config.lunchDurationMin,
                      lunchDurationMax: duration,
                      endTimeMax: config.endTimeMax,
                    ));
                  }
                },
              ),
            ),
          ],
        ),
        Divider(),
      ],
    );
  }

  Widget _buildEndTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Heure de fin maximale',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ListTile(
          title: Text('Heure limite'),
          subtitle: Text('${_dateTimeToTimeOfDay(config.endTimeMax).format(context)}'),
          onTap: () => _selectTime(
            context,
            'Heure limite',
            config.endTimeMax,
            (time) => setState(() => config = TimesheetGenerationConfig(
              startTimeMin: config.startTimeMin,
              startTimeMax: config.startTimeMax,
              lunchStartMin: config.lunchStartMin,
              lunchStartMax: config.lunchStartMax,
              lunchDurationMin: config.lunchDurationMin,
              lunchDurationMax: config.lunchDurationMax,
              endTimeMax: time,
            )),
          ),
        ),
        Divider(),
      ],
    );
  }
}
