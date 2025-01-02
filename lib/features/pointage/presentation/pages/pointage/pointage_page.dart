import 'package:flutter/material.dart';

import '../../widgets/pointage_widget/pointage_widget.dart';

class PointagePage extends StatelessWidget {
  const PointagePage({super.key});


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Pointage'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      backgroundColor: Colors.teal[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              PointageWidget(selectedDate: DateTime.now()),
            ],
          ),
        ),
      ),
    );
  }
}
