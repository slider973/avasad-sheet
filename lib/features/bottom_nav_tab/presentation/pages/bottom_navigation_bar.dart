import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../../pointage/presentation/pages/pdf/pages/pdf_document_page.dart';
import '../../../preference/presentation/pages/preference.dart';
import '../../../pointage/presentation/pages/pointage/pointage_page.dart';
import '../../../pointage/presentation/pages/pdf/pages/pdf_document_page_old.dart';
import '../../../pointage/presentation/widgets/pointage_widget/pointage_widget.dart';
import '../../../pointage/presentation/widgets/timesheet_calendar_widget/timesheet_calendar_widget.dart';
import '../widgets/bottom_navigation_bar_widget.dart';
import 'bloc/bottom_navigation_bar_bloc.dart';

class BottomNavigationBarPage extends StatelessWidget {
  const BottomNavigationBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BlocBuilder<BottomNavigationBarBloc, int>(
      builder: (context, currentIndex) {
        Widget currentScreen;
        switch (currentIndex) {
          case 0:
            currentScreen = const PointagePage();
            break;
          case 1:
            currentScreen =  PdfDocumentPage();
            break;
          case 2:
            currentScreen = const TimesheetCalendarWidget();
            break;
          case 3:
            currentScreen = PreferencesPage();
            break;
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
