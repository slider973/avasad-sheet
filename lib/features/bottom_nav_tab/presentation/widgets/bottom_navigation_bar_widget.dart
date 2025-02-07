// bottom_navigation_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/bloc/bottom_navigation_bar_bloc.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BottomNavigationBarBloc, int>(
      builder: (context, currentIndex) {
        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            switch (index) {
              case 0:
                context
                    .read<BottomNavigationBarBloc>()
                    .add(BottomNavigationBarEvent.tab1);
                break;
              case 1:
                context
                    .read<BottomNavigationBarBloc>()
                    .add(BottomNavigationBarEvent.tab2);
                break;
              case 2:
                context
                    .read<BottomNavigationBarBloc>()
                    .add(BottomNavigationBarEvent.tab3);
                break;
                case 3:
                context
                    .read<BottomNavigationBarBloc>()
                    .add(BottomNavigationBarEvent.tab4);
                break;
              case 4: // Nouvel onglet pour les anomalies
                context.read<BottomNavigationBarBloc>()
                    .add(BottomNavigationBarEvent.tab5);
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Pointage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.business),
              label: 'Time Sheet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendrier',
            ),
            BottomNavigationBarItem( // Nouvel item
              icon: Icon(Icons.warning),
              label: 'Anomalies',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Réglages',
            ),
          ],
        );
      },
    );
  }
}
