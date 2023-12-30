import 'package:flutter/material.dart';
import 'package:time_sheet/services/logger_service.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time sheet')
      ),
      body: Center(
        child: InkWell(
          child: const Text('GeneratePdf'),
          onTap: (){
            logger.i('pdf generating...');
          },
        ),
      ),
    );
  }
}
