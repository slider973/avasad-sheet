import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../../widgets/pointage_widget/pointage_widget.dart';

class PointagePage extends StatefulWidget {
  const PointagePage({super.key});

  @override
  State<PointagePage> createState() => _PointagePageState();
}

class _PointagePageState extends State<PointagePage> {
  @override
  void initState() {
    super.initState();
    // Forcer le chargement des données du jour actuel à l'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayData();
    });
  }

  void _loadTodayData() {
    // Formater la date d'aujourd'hui dans le format attendu par le BLoC
    final today = DateTime.now();
    final formattedDate = DateFormat("dd-MMM-yy").format(today);

    // Déclencher le chargement des données pour aujourd'hui
    final bloc = context.read<TimeSheetBloc>();
    bloc.add(LoadTimeSheetDataEvent(formattedDate));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointage'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTodayData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      backgroundColor: Colors.teal[50],
      body: PointageWidget(selectedDate: today),
    );
  }
}
