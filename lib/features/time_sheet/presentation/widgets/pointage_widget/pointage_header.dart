import 'package:flutter/material.dart';

class PointageHeader extends StatelessWidget {
  const PointageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return  const Text(
      'Heure de pointage',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }
}
