import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../pointage/presentation/pages/anomaly/anomaly.dart';
import '../../../pointage/presentation/pages/pdf/pages/pdf_document_page.dart';
import '../../../preference/presentation/pages/preference.dart';
import '../../../pointage/presentation/pages/pointage/pointage_page.dart';
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
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await permission.handlePermission(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const AppDrawer(),
        body: BlocBuilder<BottomNavigationBarBloc, int>(
          builder: (context, currentIndex) {
            Widget currentScreen;
            switch (currentIndex) {
              case 0:
                currentScreen = const PointagePage();
                break;
              case 1:
                currentScreen = PdfDocumentPage();
                break;
              case 2:
                currentScreen = const TimesheetCalendarWidget();
                break;
              case 3:
                currentScreen = AnomalyView();
                break;
              case 4: // Nouvel écran
                currentScreen = PreferencesPage(); // Votre vue d'anomalies
              default:
                currentScreen = const PointagePage();
            }
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Center(
                    child: currentScreen,
                  ),
                ),
                const BottomNavigationBarWidget(),
              ],
            );
          },
        ));
  }
}
