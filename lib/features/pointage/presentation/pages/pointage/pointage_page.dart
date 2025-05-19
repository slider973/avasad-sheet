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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Pointage'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      backgroundColor: Colors.teal[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              PointageWidget(selectedDate: DateTime.now()),
            ],
          ),
        ),
      ),
    );
  }
}
