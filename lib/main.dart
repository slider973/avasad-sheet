import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:time_sheet/services/logger_service.dart';
import 'package:time_sheet/services/service_factory.dart';
import 'dart:io';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'features/bottom_nav_tab/presentation/pages/bottom_navigation_bar.dart';
import 'features/preference/presentation/pages/initial_check_page.dart';
import 'features/preference/presentation/pages/onboarding_page.dart';
import './services/injection_container.dart' as di;
import 'package:window_manager/window_manager.dart';

void main() async {
  logger.i('main');
  WidgetsFlutterBinding.ensureInitialized();
  await _configureLocalTimeZone();
  await initializeDateFormatting('fr_CH', null);
  // Must add this line.
  if (Platform.isWindows) {
    await configWindows();
  }

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://881fc425e6497d1454c99fe537d80968@o4507600245817344.ingest.de.sentry.io/4507600249159760';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
    },
  );

  await di.setup();

  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

Future<void> configWindows() async {
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 1000),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    maximumSize: Size(500, 1000),
    minimumSize: Size(500, 1000),
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ServiceFactory(
      child: MaterialApp(
        title: 'Planet Time Sheet ',
        locale: const Locale('fr', 'CH'),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          primaryColor: Colors.teal,
          useMaterial3: false,
        ),
        home: const InitialCheckPage(),
        routes: {
          '/main': (context) => const BottomNavigationBarPage(),
          '/onboarding': (context) => const OnboardingPage(),
        },
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }
}

Future<void> _configureLocalTimeZone() async {
  if (kIsWeb || Platform.isLinux) {
    return;
  }
  tz.initializeTimeZones();
  final String timeZoneName = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(timeZoneName));
}
