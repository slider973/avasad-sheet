import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:time_sheet/pdf/presentation/pages/time_sheet_page.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/services/service_factory.dart';

import 'home/presentation/pages/home_page.dart';
import 'pdf/presentation/pages/pdf_document.dart';
import 'pdf/presentation/widgets/calandar_page/calandar_page.dart';

import './services/injection_container.dart' as di;



void main() async {

  logger.i('main');
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_CH', null);

  await di.setup();
  initializeDateFormatting().then((_) => runApp(const MyApp()));
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
        useMaterial3: false,
      ),
      home: const TimeSheetPage(),
    ));
  }
}

