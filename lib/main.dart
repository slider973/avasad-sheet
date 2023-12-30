import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/services/service_factory.dart';

import 'home/presentation/pages/home_page.dart';
import 'pdf/presentation/pages/pdf_document.dart';



void main() {

  logger.i('main');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ServiceFactory(child: MaterialApp(
      title: 'Time Sheet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const PdfDocument(),
    ));
  }
}

