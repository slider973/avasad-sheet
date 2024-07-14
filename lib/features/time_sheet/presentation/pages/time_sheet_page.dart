import 'package:flutter/material.dart';

import '../widgets/pointage_widget/pointage_widget.dart';

class TimeSheetPage extends StatelessWidget {
  const TimeSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pointage')),
      backgroundColor: Colors.teal[50],
      body: const SingleChildScrollView(
        child: Column(
          children: [
            PointageWidget(),
          ],
        ),
      ),
    );
  }
}

