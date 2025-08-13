import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:time_sheet/services/watch_service.dart';

class AppleWatchStatusCard extends StatefulWidget {
  const AppleWatchStatusCard({super.key});

  @override
  State<AppleWatchStatusCard> createState() => _AppleWatchStatusCardState();
}

class _AppleWatchStatusCardState extends State<AppleWatchStatusCard> {
  final WatchService _watchService = GetIt.I<WatchService>();
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.watch,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Apple Watch',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<String>(
              stream: _watchService.stateStream,
              initialData: _watchService.currentState,
              builder: (context, snapshot) {
                final isConnected = _watchService.isConnected;
                final currentState = snapshot.data ?? 'Non commencé';
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isConnected ? 'Connectée' : 'Non connectée',
                          style: TextStyle(
                            color: isConnected ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'État: $currentState',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (!isConnected) 
                      Text(
                        '(Mode hors ligne - sync auto)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (!_watchService.isConnected)
              Text(
                'Ouvrez l\'app sur votre Apple Watch pour la connecter',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }
}