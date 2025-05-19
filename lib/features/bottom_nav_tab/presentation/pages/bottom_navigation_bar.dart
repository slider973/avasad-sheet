import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../pointage/presentation/pages/anomaly/anomaly.dart';
import '../../../pointage/presentation/pages/pdf/pages/pdf_document_page.dart';
import '../../../preference/presentation/pages/preference.dart';
import '../../../pointage/presentation/pages/pointage/pointage_page.dart';
import '../../../pointage/presentation/pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';
import '../../../pointage/presentation/widgets/timesheet_calendar_widget/timesheet_calendar_widget.dart';
import '../widgets/bottom_navigation_bar_widget.dart';
import 'app_drawer.dart';
import 'bloc/bottom_navigation_bar_bloc.dart';
import '../../../../services/request_permission_handler.dart' as permission;

class BottomNavigationBarPage extends StatefulWidget {
  const BottomNavigationBarPage({super.key});

  @override
  State<BottomNavigationBarPage> createState() =>
      _BottomNavigationBarPageState();
}

class _BottomNavigationBarPageState extends State<BottomNavigationBarPage> {
  // Liste des écrans pré-initialisés pour conserver leur état
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    
    // Initialiser tous les écrans une seule fois
    _screens = [
      const PointagePage(),
      PdfDocumentPage(),
      const TimesheetCalendarWidget(),
      AnomalyView(),
      PreferencesPage(),
    ];
  }

  Future<void> _checkPermissions() async {
    await permission.handlePermission(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const AppDrawer(),
        body: BlocConsumer<BottomNavigationBarBloc, int>(
          listener: (context, currentIndex) {
            // Si l'utilisateur navigue vers l'onglet pointage (index 0),
            // forcer le chargement des données du jour actuel
            if (currentIndex == 0) {
              // Formater la date d'aujourd'hui dans le format attendu par le BLoC
              final today = DateTime.now();
              final formattedDate = DateFormat("dd-MMM-yy").format(today);
              
              // Déclencher le chargement des données pour aujourd'hui
              final bloc = context.read<TimeSheetBloc>();
              bloc.add(LoadTimeSheetDataEvent(formattedDate));
            }
          },
          builder: (context, currentIndex) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: IndexedStack(
                    index: currentIndex,
                    children: _screens,
                  ),
                ),
                const BottomNavigationBarWidget(),
              ],
            );
          },
        ));
  }
}
