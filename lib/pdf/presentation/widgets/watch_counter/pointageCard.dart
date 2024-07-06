import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PointageCard extends StatelessWidget {
  final String type;
  final DateTime heure;
  final VoidCallback onModifier;

  const PointageCard({
    Key? key,
    required this.type,
    required this.heure,
    required this.onModifier,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('HH:mm').format(heure)),
              ],
            ),
            ElevatedButton(
              onPressed: onModifier,
              child: Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }
}