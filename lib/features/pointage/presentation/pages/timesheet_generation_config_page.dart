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
  DateTime selectedMonth = DateTime.now();

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
            _buildMonthSelector(),
            SizedBox(height: 20),
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
                    GenerateMonthlyTimesheetEvent(
                      config: config,
                      month: selectedMonth,
                    ),
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

  Widget _buildMonthSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionner le mois',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            InkWell(
              onTap: () async {
                // Utiliser showModalBottomSheet pour afficher un sélecteur de mois personnalisé
                final result = await showModalBottomSheet<DateTime>(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                      height: 300,
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Sélectionner le mois',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: 12,
                              itemBuilder: (context, index) {
                                final month = index + 1;
                                final monthDate = DateTime(selectedMonth.year, month);
                                final isSelected = selectedMonth.month == month;
                                
                                return ListTile(
                                  title: Text(
                                    '${_getMonthName(month)} ${selectedMonth.year}',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.teal : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                    month == 1 
                                      ? 'Du 21 décembre ${selectedMonth.year - 1} au 20 janvier ${selectedMonth.year}'
                                      : 'Du 21 ${_getMonthName(month - 1)} au 20 ${_getMonthName(month)} ${selectedMonth.year}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  trailing: isSelected ? Icon(Icons.check, color: Colors.teal) : null,
                                  onTap: () {
                                    Navigator.pop(context, monthDate);
                                  },
                                );
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // Année précédente
                                  setState(() {
                                    selectedMonth = DateTime(selectedMonth.year - 1, selectedMonth.month);
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text('< ${selectedMonth.year - 1}'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Année suivante
                                  setState(() {
                                    selectedMonth = DateTime(selectedMonth.year + 1, selectedMonth.month);
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text('${selectedMonth.year + 1} >'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
                
                if (result != null) {
                  setState(() {
                    selectedMonth = result;
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getMonthName(selectedMonth.month)} ${selectedMonth.year}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Icon(Icons.calendar_today, color: Colors.teal),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return monthNames[month - 1];
  }
}
