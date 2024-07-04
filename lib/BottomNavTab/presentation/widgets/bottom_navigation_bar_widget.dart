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
              label: 'Liste de pointage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Pdf',
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
