import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../preference/presentation/pages/preference.dart';
import '../../../time_sheet/presentation/pages/pdf_document.dart';
import '../../../time_sheet/presentation/pages/time-sheet/bloc/time_sheet_list/time_sheet_list_bloc.dart';
import '../../../time_sheet/presentation/pages/time_sheet_page.dart';
import '../../../time_sheet/presentation/pdf_document_page.dart';
import '../../../time_sheet/presentation/widgets/pointage/pointage_layout.dart';
import '../../../time_sheet/presentation/widgets/pointage/pointage_widget.dart';
import '../../../time_sheet/presentation/widgets/timesheet_calendar_widget/timesheet_calendar_widget.dart';
import '../../../time_sheet/presentation/widgets/timesheet_entries_view.dart';
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
            currentScreen = const PointageWidget();
            break;
          case 1:
            currentScreen = PdfDocumentPage();
            break;
          case 2:
            currentScreen = TimesheetCalendarWidget();
            break;
          case 3:
            currentScreen = PreferencesPage();
            break;
          default:
            currentScreen = const TimeSheetPage();
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
