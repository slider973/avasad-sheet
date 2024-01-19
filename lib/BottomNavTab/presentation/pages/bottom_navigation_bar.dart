import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../pdf/presentation/pages/time_sheet_page.dart';
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
            currentScreen = const TimeSheetPage();
            break;
          case 1:
            currentScreen = const Text('Business');
            break;
          case 2:
            currentScreen = const Text('School');
            break;
          default:
            currentScreen = const Text('Home');
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
