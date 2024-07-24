import 'package:flutter/material.dart';

import '../../widgets/pointage_widget/pointage_widget.dart';

class PointagePage extends StatelessWidget {
  const PointagePage({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointage'),
        elevation: 0,
      ),
      backgroundColor: Colors.teal[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            PointageWidget(selectedDate: DateTime.now()),
          ],
        ),
      ),
    );
  }
}
