import 'package:flutter/material.dart';
import 'package:time_sheet/features/preference/presentation/widgets/weekend_configuration_widget.dart';

class WeekendSettingsPage extends StatelessWidget {
  const WeekendSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        elevation: 0,
        title: const Text('Paramètres Weekend'),
      ),
      body: const WeekendConfigurationWidget(),
    );
  }
}
