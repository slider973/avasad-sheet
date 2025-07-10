// bottom_navigation_bar_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../pages/bloc/bottom_navigation_bar_bloc.dart';
import '../../../pointage/presentation/pages/pdf/bloc/anomaly/anomaly_bloc.dart';

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
              case 4:
                context
                    .read<BottomNavigationBarBloc>()
                    .add(BottomNavigationBarEvent.tab5);
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint),
              label: 'Pointage',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.description),
              label: 'Time Sheet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Calendrier',
            ),
            BottomNavigationBarItem(
              icon: AnomalyIconWithBadge(),
              label: 'Anomalies',
            ),
          ],
        );
      },
    );
  }
}

class AnomalyIconWithBadge extends StatelessWidget {
  const AnomalyIconWithBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnomalyBloc, AnomalyState>(
      buildWhen: (previous, current) {
        // Ne rebuild que si le nombre d'anomalies non résolues change
        if (previous is AnomalyLoaded && current is AnomalyLoaded) {
          final previousCount = previous.anomalies.where((a) => !a.isResolved).length;
          final currentCount = current.anomalies.where((a) => !a.isResolved).length;
          return previousCount != currentCount;
        }
        // Rebuild si le type d'état change (loading -> loaded, error, etc.)
        return previous.runtimeType != current.runtimeType;
      },
      builder: (context, state) {
        int unresolvedCount = 0;
        
        if (state is AnomalyLoaded) {
          unresolvedCount = state.anomalies.where((anomaly) => !anomaly.isResolved).length;
        }
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.warning),
            if (unresolvedCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unresolvedCount > 99 ? '99+' : unresolvedCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
