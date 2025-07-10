import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../pages/time-sheet/bloc/time_sheet/time_sheet_bloc.dart';

class QuickActionsCard extends StatelessWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeSheetBloc, TimeSheetState>(
      builder: (context, state) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.fingerprint, color: Colors.teal, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pointage rapide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Afficher l'état actuel et les boutons de pointage
                if (state is TimeSheetDataState) ...[
                  _buildCurrentStateIndicator(state.entry.currentState),
                  const SizedBox(height: 16),
                  _buildPointageButtons(context, state.entry.currentState),
                ] else ...[
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentStateIndicator(String currentState) {
    Color stateColor;
    IconData stateIcon;
    
    switch (currentState) {
      case 'Entrée':
      case 'Reprise':
        stateColor = Colors.green;
        stateIcon = Icons.play_arrow;
        break;
      case 'Pause':
        stateColor = Colors.orange;
        stateIcon = Icons.pause;
        break;
      case 'Sortie':
        stateColor = Colors.red;
        stateIcon = Icons.stop;
        break;
      default:
        stateColor = Colors.grey;
        stateIcon = Icons.radio_button_unchecked;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(stateIcon, color: stateColor),
          const SizedBox(width: 8),
          Text(
            'État actuel: $currentState',
            style: TextStyle(
              color: stateColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointageButtons(BuildContext context, String currentState) {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm').format(now);
    
    switch (currentState) {
      case 'Non commencé':
        return _buildPointageButton(
          context,
          'Commencer la journée',
          'Pointer l\'entrée à $formattedTime',
          Icons.login,
          Colors.green,
          () => _handlePointage(context, 'Entrée', now),
        );
      
      case 'Entrée':
        return Column(
          children: [
            _buildPointageButton(
              context,
              'Prendre une pause',
              'Commencer la pause à $formattedTime',
              Icons.coffee,
              Colors.orange,
              () => _handlePointage(context, 'Pause', now),
            ),
            const SizedBox(height: 12),
            _buildPointageButton(
              context,
              'Terminer la journée',
              'Pointer la sortie à $formattedTime',
              Icons.logout,
              Colors.red,
              () => _handlePointage(context, 'Sortie', now),
            ),
          ],
        );
      
      case 'Pause':
        return _buildPointageButton(
          context,
          'Reprendre le travail',
          'Terminer la pause à $formattedTime',
          Icons.play_arrow,
          Colors.green,
          () => _handlePointage(context, 'Reprise', now),
        );
      
      case 'Reprise':
        return _buildPointageButton(
          context,
          'Terminer la journée',
          'Pointer la sortie à $formattedTime',
          Icons.logout,
          Colors.red,
          () => _handlePointage(context, 'Sortie', now),
        );
      
      case 'Sortie':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Journée terminée',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  void _handlePointage(BuildContext context, String action, DateTime time) {
    final bloc = context.read<TimeSheetBloc>();
    final formattedDate = DateFormat("dd-MMM-yy").format(time);
    
    switch (action) {
      case 'Entrée':
        bloc.add(TimeSheetEnterEvent(time));
        break;
      case 'Pause':
        bloc.add(TimeSheetStartBreakEvent(time));
        break;
      case 'Reprise':
        bloc.add(TimeSheetEndBreakEvent(time));
        break;
      case 'Sortie':
        bloc.add(TimeSheetOutEvent(time));
        break;
    }
    
    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action enregistré à ${DateFormat('HH:mm').format(time)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildPointageButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
